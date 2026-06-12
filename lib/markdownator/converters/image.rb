# frozen_string_literal: true

module Markdownator
  module Converters
    # Converts an image into Markdown metadata (filename + EXIF fields). When a
    # captioner is supplied via the `captioner:` option, its description is
    # appended. A captioner is any object responding to
    # `#caption(io, stream_info) -> String`.
    class Image < Base
      EXTENSIONS = %w[jpg jpeg png gif tif tiff].freeze
      MIMETYPES = %w[image/jpeg image/png image/gif image/tiff].freeze

      # EXIF fields worth surfacing, in display order.
      EXIF_FIELDS = %i[
        date_time make model orientation
        f_number exposure_time iso_speed_ratings focal_length
        gps_latitude gps_longitude image_description
      ].freeze

      def accepts?(_io, stream_info)
        matches?(stream_info, extensions: EXTENSIONS, mimetypes: MIMETYPES)
      end

      def convert(io, stream_info, **options)
        lines = []
        lines << "# #{stream_info.filename}" if stream_info.filename

        metadata = exif_metadata(io, stream_info)
        metadata.each { |key, value| lines << "- **#{key}**: #{value}" }

        caption = caption_for(io, stream_info, options[:captioner])
        lines << "\n#{caption}" if caption

        Result.new(markdown: lines.join("\n").strip, metadata: metadata)
      end

      private

      def exif_metadata(io, stream_info)
        return {} unless jpeg_or_tiff?(stream_info)

        Markdownator.require_optional("exifr", feature: "image metadata extraction")
        io.rewind if io.respond_to?(:rewind)
        reader = exif_reader(stream_info, io)
        return {} if reader.nil?

        EXIF_FIELDS.each_with_object({}) do |field, acc|
          next unless reader.respond_to?(field)

          value = reader.public_send(field)
          acc[field.to_s] = value.to_s unless value.nil? || value.to_s.empty?
        end
      rescue StandardError
        {}
      ensure
        io.rewind if io.respond_to?(:rewind)
      end

      def exif_reader(stream_info, io)
        if tiff?(stream_info)
          EXIFR::TIFF.new(io)
        else
          EXIFR::JPEG.new(io)
        end
      end

      def jpeg_or_tiff?(stream_info)
        ext = stream_info.extension
        mime = stream_info.guessed_mimetype
        %w[jpg jpeg tif tiff].include?(ext) || %w[image/jpeg image/tiff].include?(mime)
      end

      def tiff?(stream_info)
        stream_info.extension&.start_with?("tif") || stream_info.guessed_mimetype == "image/tiff"
      end

      def caption_for(io, stream_info, captioner)
        return nil unless captioner.respond_to?(:caption)

        io.rewind if io.respond_to?(:rewind)
        text = captioner.caption(io, stream_info)
        text unless text.nil? || text.to_s.strip.empty?
      rescue StandardError
        nil
      end
    end
  end
end
