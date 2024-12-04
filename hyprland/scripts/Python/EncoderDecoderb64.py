import base64

import sys
from PyQt6.QtWidgets import QApplication, QMainWindow, QPushButton, QFileDialog, QVBoxLayout, QWidget, QLabel
from PyQt6.QtCore import Qt


class EncoderDecoderApp(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("PDF Merger")
        self.setGeometry(100, 100, 250, 150)
        layout = QVBoxLayout()
        
        self.label = QLabel("No files selected")
        layout.addWidget(self.label)
        
        encode_button = QPushButton("Encode to Base64")
        encode_button.clicked.connect(self.zip_and_encode)
        layout.addWidget(encode_button)
        
        decode_button = QPushButton("Decode Base64")
        decode_button.clicked.connect(self.decode_and_unzip)
        layout.addWidget(decode_button)
        
        container = QWidget()
        container.setLayout(layout)
        self.setCentralWidget(container)
  
    def zip_and_encode(self):      
        input_file, _ = QFileDialog.getOpenFileName(self, "Select File To Encode")
        if not input_file:
            return

        with open(input_file, 'rb') as file:
            encoded_data = file.read()
        
        encoded_data = base64.b64encode(encoded_data).decode('utf-8')
        
        output_file, _ = QFileDialog.getSaveFileName(self, "Save Encoded File")
        if not output_file:
            return

        with open(output_file, 'w') as file:
            file.write(encoded_data)

        self.label.setText("File encoded successfully!")

    def decode_and_unzip(self):
            input_file, _ = QFileDialog.getOpenFileName(self, "Select Encoded File", "", "Text Files (*.txt)")
            if not input_file:
                return

            with open(input_file, 'r') as file:
                encoded_data = file.read()

            decoded_data = base64.b64decode(encoded_data)
            

            output_file, _ = QFileDialog.getSaveFileName(self, "Save Decoded File")
            if not output_file:
                return

            with open(output_file, 'wb') as file:
                file.write(decoded_data)

            self.label.setText("File decoded successfully!")


if __name__ == "__main__":
    print(sys.argv)
    app = QApplication(sys.argv)
    window = EncoderDecoderApp()
    window.show()
    sys.exit(app.exec())
