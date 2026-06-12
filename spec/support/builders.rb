# frozen_string_literal: true

require "zip"
require "stringio"

# Helpers that build minimal, valid binary documents in-memory so converter
# specs don't need committed binary fixtures.
module Builders
  module_function

  def zip_bytes(entries)
    buffer = StringIO.new
    Zip::OutputStream.write_buffer(buffer) do |out|
      entries.each do |name, content|
        out.put_next_entry(name)
        out.write(content)
      end
    end
    buffer.string
  end

  def docx_bytes
    document = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:body>
          <w:p><w:pPr><w:pStyle w:val="Heading1"/></w:pPr><w:r><w:t>Greeting</w:t></w:r></w:p>
          <w:p><w:r><w:t>Hello world.</w:t></w:r></w:p>
          <w:tbl>
            <w:tr><w:tc><w:p><w:r><w:t>A</w:t></w:r></w:p></w:tc><w:tc><w:p><w:r><w:t>B</w:t></w:r></w:p></w:tc></w:tr>
            <w:tr><w:tc><w:p><w:r><w:t>1</w:t></w:r></w:p></w:tc><w:tc><w:p><w:r><w:t>2</w:t></w:r></w:p></w:tc></w:tr>
          </w:tbl>
        </w:body>
      </w:document>
    XML
    zip_bytes("word/document.xml" => document)
  end

  def pptx_bytes
    slide = lambda do |text|
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"
               xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
          <p:cSld><p:spTree><p:sp><p:txBody>
            <a:p><a:r><a:t>#{text}</a:t></a:r></a:p>
          </p:txBody></p:sp></p:spTree></p:cSld>
        </p:sld>
      XML
    end
    zip_bytes(
      "ppt/slides/slide1.xml" => slide.call("First slide"),
      "ppt/slides/slide2.xml" => slide.call("Second slide")
    )
  end

  def epub_bytes
    container = <<~XML
      <?xml version="1.0"?>
      <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
        <rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>
      </container>
    XML
    opf = <<~XML
      <?xml version="1.0"?>
      <package xmlns="http://www.idpf.org/2007/opf" version="2.0">
        <metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:title>My Book</dc:title></metadata>
        <manifest><item id="c1" href="chapter1.xhtml" media-type="application/xhtml+xml"/></manifest>
        <spine><itemref idref="c1"/></spine>
      </package>
    XML
    chapter = <<~XML
      <?xml version="1.0"?>
      <html xmlns="http://www.w3.org/1999/xhtml"><body>
        <h1>Chapter One</h1><p>It was a dark and stormy night.</p>
      </body></html>
    XML
    zip_bytes(
      "mimetype" => "application/epub+zip",
      "META-INF/container.xml" => container,
      "OEBPS/content.opf" => opf,
      "OEBPS/chapter1.xhtml" => chapter
    )
  end

  def xlsx_bytes
    zip_bytes(
      "[Content_Types].xml" => <<~XML,
        <?xml version="1.0" encoding="UTF-8"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="xml" ContentType="application/xml"/>
          <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
          <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
          <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
        </Types>
      XML
      "_rels/.rels" => <<~XML,
        <?xml version="1.0" encoding="UTF-8"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
        </Relationships>
      XML
      "xl/workbook.xml" => <<~XML,
        <?xml version="1.0" encoding="UTF-8"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
                  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <sheets><sheet name="Data" sheetId="1" r:id="rId1"/></sheets>
        </workbook>
      XML
      "xl/_rels/workbook.xml.rels" => <<~XML,
        <?xml version="1.0" encoding="UTF-8"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
        </Relationships>
      XML
      "xl/styles.xml" => <<~XML,
        <?xml version="1.0" encoding="UTF-8"?>
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"/>
      XML
      "xl/worksheets/sheet1.xml" => <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <sheetData>
            <row r="1"><c r="A1" t="inlineStr"><is><t>Name</t></is></c><c r="B1" t="inlineStr"><is><t>Age</t></is></c></row>
            <row r="2"><c r="A2" t="inlineStr"><is><t>Alice</t></is></c><c r="B2"><v>30</v></c></row>
          </sheetData>
        </worksheet>
      XML
    )
  end

  # A minimal one-page PDF that renders the text "Hello PDF".
  def pdf_bytes
    objects = []
    objects << "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n"
    objects << "2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n"
    objects << "3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] " \
               "/Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n"
    stream = "BT /F1 24 Tf 72 700 Td (Hello PDF) Tj ET"
    objects << "4 0 obj\n<< /Length #{stream.bytesize} >>\nstream\n#{stream}\nendstream\nendobj\n"
    objects << "5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n"

    pdf = +"%PDF-1.4\n"
    offsets = []
    objects.each do |obj|
      offsets << pdf.bytesize
      pdf << obj
    end
    xref_start = pdf.bytesize
    pdf << "xref\n0 #{objects.length + 1}\n"
    pdf << "0000000000 65535 f \n"
    offsets.each { |offset| pdf << format("%010d 00000 n \n", offset) }
    pdf << "trailer\n<< /Size #{objects.length + 1} /Root 1 0 R >>\n"
    pdf << "startxref\n#{xref_start}\n%%EOF\n"
    pdf
  end
end
