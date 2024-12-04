import sys
import zlib
import base64
from PyQt6.QtWidgets import QApplication, QMainWindow, QPushButton, QFileDialog, QVBoxLayout, QWidget, QLabel
from PyQt6.QtCore import Qt
from PyPDF2 import PdfMerger, PdfReader, PdfWriter
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from io import BytesIO

class PDFMergerApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("PDF Merger")
        self.setGeometry(100, 100, 300, 250)

        layout = QVBoxLayout()

        self.label = QLabel("No files selected")
        layout.addWidget(self.label)

        select_button = QPushButton("Select PDF Files")
        select_button.clicked.connect(self.select_files)
        layout.addWidget(select_button)

        merge_button = QPushButton("Merge PDFs")
        merge_button.clicked.connect(self.merge_pdfs)
        layout.addWidget(merge_button)

        encode_button = QPushButton("Zip and Encode to Base64")
        encode_button.clicked.connect(self.zip_and_encode)
        layout.addWidget(encode_button)

        decode_button = QPushButton("Decode and Unzip Base64")
        decode_button.clicked.connect(self.decode_and_unzip)
        layout.addWidget(decode_button)

        container = QWidget()
        container.setLayout(layout)
        self.setCentralWidget(container)

        self.pdf_files = []
        self.merged_pdf_path = None

    def select_files(self):
        files, _ = QFileDialog.getOpenFileNames(self, "Select PDF Files", "", "PDF Files (*.pdf)")
        if files:
            self.pdf_files = files
            self.label.setText(f"{len(files)} files selected")

    def merge_pdfs(self):
        if not self.pdf_files:
            self.label.setText("No files selected")
            return

        output_file, _ = QFileDialog.getSaveFileName(self, "Save Merged PDF", "", "PDF Files (*.pdf)")
        if not output_file:
            return

        merger = PdfMerger()

        for pdf_file in self.pdf_files:
            original_pdf = PdfReader(pdf_file)
            watermarked_pdf = PdfWriter()

            for page_num in range(len(original_pdf.pages)):
                page = original_pdf.pages[page_num]
                
                # Create a watermark with the filename
                packet = BytesIO()
                can = canvas.Canvas(packet, pagesize=letter)
                can.setFont("Helvetica", 8)
                can.setFillColorRGB(0.5, 0.5, 0.5)  # Gray color
                can.drawRightString(570, 20, pdf_file.split("/")[-1])
                can.save()

                packet.seek(0)
                watermark = PdfReader(packet)
                page.merge_page(watermark.pages[0])

                watermarked_pdf.add_page(page)

            watermarked_pdf_stream = BytesIO()
            watermarked_pdf.write(watermarked_pdf_stream)
            watermarked_pdf_stream.seek(0)

            merger.append(watermarked_pdf_stream)

        merger.write(output_file)
        merger.close()

        self.merged_pdf_path = output_file
        self.label.setText("PDFs merged successfully!")

    def zip_and_encode(self):
        if not self.merged_pdf_path:
            self.label.setText("No merged PDF to encode")
            return

        with open(self.merged_pdf_path, 'rb') as file:
            pdf_data = file.read()

        compressed_data = zlib.compress(pdf_data, level=9)  # Highest compression level
        encoded_data = base64.b64encode(compressed_data).decode('utf-8')

        output_file, _ = QFileDialog.getSaveFileName(self, "Save Encoded File", "", "Text Files (*.txt)")
        if not output_file:
            return

        with open(output_file, 'w') as file:
            file.write(encoded_data)

        self.label.setText("PDF zipped and encoded successfully!")

    def decode_and_unzip(self):
        input_file, _ = QFileDialog.getOpenFileName(self, "Select Encoded File", "", "Text Files (*.txt)")
        if not input_file:
            return

        with open(input_file, 'r') as file:
            encoded_data = file.read()

        compressed_data = base64.b64decode(encoded_data)
        pdf_data = zlib.decompress(compressed_data)

        output_file, _ = QFileDialog.getSaveFileName(self, "Save Decoded PDF", "", "PDF Files (*.pdf)")
        if not output_file:
            return

        with open(output_file, 'wb') as file:
            file.write(pdf_data)

        self.label.setText("File decoded and unzipped successfully!")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = PDFMergerApp()
    window.show()
    sys.exit(app.exec())