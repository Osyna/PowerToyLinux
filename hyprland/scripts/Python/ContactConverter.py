import sys
import csv
import os
from PyQt6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, 
                             QPushButton, QLabel, QFileDialog, QComboBox, QCheckBox, 
                             QProgressBar, QListWidget, QLineEdit, QGroupBox, QMessageBox,
                             QListWidgetItem)
from PyQt6.QtGui import QIcon, QFont
from PyQt6.QtCore import Qt, QThread, pyqtSignal
import vobject

class ContactConverter(QThread):
    progress_update = pyqtSignal(int)
    conversion_complete = pyqtSignal(object)

    def __init__(self, input_files, output_dir, output_format, merge_files, output_filename):
        super().__init__()
        self.input_files = input_files
        self.output_dir = output_dir
        self.output_format = output_format
        self.merge_files = merge_files
        self.output_filename = output_filename

    def run(self):
        all_contacts = []
        total_files = len(self.input_files)

        for i, file in enumerate(self.input_files):
            contacts = self.read_file(file)
            all_contacts.extend(contacts)
            self.progress_update.emit(int((i + 1) / total_files * 50))  # First 50% for reading

        if self.merge_files:
            output_file = os.path.join(self.output_dir, self.output_filename)
            self.save_contacts(all_contacts, output_file)
            self.progress_update.emit(100)
            self.conversion_complete.emit(output_file)
        else:
            output_files = []
            for i, file in enumerate(self.input_files):
                base_name = os.path.splitext(os.path.basename(file))[0]
                output_file = self.generate_unique_filename(self.output_dir, base_name)
                contacts_from_file = self.read_file(file)
                self.save_contacts(contacts_from_file, output_file)
                output_files.append(output_file)
                self.progress_update.emit(50 + int((i + 1) / total_files * 50))  # Last 50% for saving
            self.conversion_complete.emit(output_files)

    def read_file(self, file_path):
        _, ext = os.path.splitext(file_path)
        if ext.lower() == '.vcf':
            return self.read_vcf(file_path)
        elif ext.lower() == '.csv':
            return self.read_csv(file_path)
        else:
            raise ValueError(f"Unsupported file format: {ext}")
        
    def read_vcf(self, file_path):
        contacts = []
        with open(file_path, 'r', encoding='utf-8') as vcf_file:
            for vcard in vobject.readComponents(vcf_file):
                contacts.append(vcard)
        return contacts

    def read_csv(self, file_path):
        contacts = []
        with open(file_path, 'r', newline='', encoding='utf-8') as csvfile:
            reader = csv.DictReader(csvfile)
            headers = reader.fieldnames
            if 'Given Name' in headers and 'Family Name' in headers:
                for row in reader:
                    contacts.append(self.google_csv_to_vcard(row))
            elif 'First Name' in headers and 'Last Name' in headers:
                for row in reader:
                    contacts.append(self.outlook_csv_to_vcard(row))
            else:
                raise ValueError("Unsupported CSV format")
        return contacts

    def google_csv_to_vcard(self, row):
        vcard = vobject.vCard()
        vcard.add('n')
        vcard.n.value = vobject.vcard.Name(
            family=row.get('Family Name', ''),
            given=row.get('Given Name', ''),
            additional=row.get('Additional Name', '')
        )
        vcard.add('fn')
        vcard.fn.value = f"{row.get('Given Name', '')} {row.get('Additional Name', '')} {row.get('Family Name', '')}".strip()

        if row.get('Organization 1 - Name'):
            vcard.add('org').value = [row['Organization 1 - Name']]
        if row.get('Organization 1 - Title'):
            vcard.add('title').value = row['Organization 1 - Title']

        for i in range(1, 4):
            phone = row.get(f'Phone {i} - Value')
            if phone:
                tel = vcard.add('tel')
                tel.value = phone
                tel_type = row.get(f'Phone {i} - Type', '').upper()
                if tel_type:
                    tel.type_param = tel_type

        for i in range(1, 4):
            email = row.get(f'E-mail {i} - Value')
            if email:
                email_field = vcard.add('email')
                email_field.value = email
                email_field.type_param = 'INTERNET'

        for i in range(1, 4):
            street = row.get(f'Address {i} - Street', '')
            city = row.get(f'Address {i} - City', '')
            region = row.get(f'Address {i} - Region', '')
            postal_code = row.get(f'Address {i} - Postal Code', '')
            country = row.get(f'Address {i} - Country', '')
            if any([street, city, region, postal_code, country]):
                adr = vcard.add('adr')
                adr.value = vobject.vcard.Address(
                    street=street,
                    city=city,
                    region=region,
                    code=postal_code,
                    country=country
                )
                adr_type = row.get(f'Address {i} - Type', '').upper()
                if adr_type:
                    adr.type_param = adr_type

        if row.get('Birthday'):
            vcard.add('bday').value = row['Birthday']

        if row.get('Notes'):
            vcard.add('note').value = row['Notes']

        return vcard

    def outlook_csv_to_vcard(self, row):
        vcard = vobject.vCard()
        vcard.add('n')
        vcard.n.value = vobject.vcard.Name(
            family=row.get('Last Name', ''),
            given=row.get('First Name', ''),
            additional=row.get('Middle Name', '')
        )
        vcard.add('fn')
        vcard.fn.value = f"{row.get('First Name', '')} {row.get('Middle Name', '')} {row.get('Last Name', '')}".strip()

        if row.get('Company'):
            vcard.add('org').value = [row['Company']]
        if row.get('Job Title'):
            vcard.add('title').value = row['Job Title']

        if row.get('Mobile Phone'):
            tel = vcard.add('tel')
            tel.value = row['Mobile Phone']
            tel.type_param = 'CELL'
        if row.get('Business Phone'):
            tel = vcard.add('tel')
            tel.value = row['Business Phone']
            tel.type_param = 'WORK'
        if row.get('Home Phone'):
            tel = vcard.add('tel')
            tel.value = row['Home Phone']
            tel.type_param = 'HOME'

        for email_key in ['E-mail Address', 'E-mail 2 Address', 'E-mail 3 Address']:
            if row.get(email_key):
                email = vcard.add('email')
                email.value = row[email_key]
                email.type_param = 'INTERNET'

        for addr_type in ['Business', 'Home']:
            street = row.get(f'{addr_type} Street', '')
            city = row.get(f'{addr_type} City', '')
            state = row.get(f'{addr_type} State', '')
            postal_code = row.get(f'{addr_type} Postal Code', '')
            country = row.get(f'{addr_type} Country/Region', '')
            if any([street, city, state, postal_code, country]):
                adr = vcard.add('adr')
                adr.value = vobject.vcard.Address(
                    street=street,
                    city=city,
                    region=state,
                    code=postal_code,
                    country=country
                )
                adr.type_param = addr_type.upper()

        if row.get('Birthday'):
            vcard.add('bday').value = row['Birthday']

        if row.get('Notes'):
            vcard.add('note').value = row['Notes']

        return vcard

    def save_contacts(self, contacts, output_file):
        if self.output_format == "VCF":
            self.save_vcf(contacts, output_file)
        elif self.output_format == "Google CSV":
            self.save_google_csv(contacts, output_file)
        elif self.output_format == "Outlook CSV":
            self.save_outlook_csv(contacts, output_file)
        else:
            raise ValueError(f"Unsupported output format: {self.output_format}")

  
    def save_vcf(self, contacts, output_file):
        with open(output_file, 'w', encoding='utf-8') as f:
            for contact in contacts:
                f.write(contact.serialize())

    def save_google_csv(self, contacts, output_file):
        fieldnames = ['Given Name', 'Additional Name', 'Family Name', 'Organization 1 - Name', 'Organization 1 - Title']
        for i in range(1, 4):
            fieldnames.extend([f'Phone {i} - Type', f'Phone {i} - Value'])
            fieldnames.extend([f'E-mail {i} - Type', f'E-mail {i} - Value'])
            fieldnames.extend([f'Address {i} - Type', f'Address {i} - Street', f'Address {i} - City',
                               f'Address {i} - Region', f'Address {i} - Postal Code', f'Address {i} - Country'])
        fieldnames.extend(['Birthday', 'Notes'])

        with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            for contact in contacts:
                row = {}
                if hasattr(contact, 'n'):
                    row['Given Name'] = contact.n.value.given
                    row['Additional Name'] = contact.n.value.additional
                    row['Family Name'] = contact.n.value.family
                if hasattr(contact, 'org'):
                    row['Organization 1 - Name'] = contact.org.value[0] if contact.org.value else ''
                if hasattr(contact, 'title'):
                    row['Organization 1 - Title'] = contact.title.value

                phone_count = email_count = address_count = 1
                for child in contact.getChildren():
                    if child.name == 'TEL' and phone_count <= 3:
                        row[f'Phone {phone_count} - Type'] = child.type_param if hasattr(child, 'type_param') else ''
                        row[f'Phone {phone_count} - Value'] = child.value
                        phone_count += 1
                    elif child.name == 'EMAIL' and email_count <= 3:
                        row[f'E-mail {email_count} - Type'] = 'INTERNET'
                        row[f'E-mail {email_count} - Value'] = child.value
                        email_count += 1
                    elif child.name == 'ADR' and address_count <= 3:
                        row[f'Address {address_count} - Type'] = child.type_param if hasattr(child, 'type_param') else ''
                        row[f'Address {address_count} - Street'] = child.value.street
                        row[f'Address {address_count} - City'] = child.value.city
                        row[f'Address {address_count} - Region'] = child.value.region
                        row[f'Address {address_count} - Postal Code'] = child.value.code
                        row[f'Address {address_count} - Country'] = child.value.country
                        address_count += 1

                if hasattr(contact, 'bday'):
                    row['Birthday'] = contact.bday.value
                if hasattr(contact, 'note'):
                    row['Notes'] = contact.note.value

                writer.writerow(row)

    def save_outlook_csv(self, contacts, output_file):
        fieldnames = ['First Name', 'Middle Name', 'Last Name', 'Company', 'Job Title',
                      'Mobile Phone', 'Business Phone', 'Home Phone',
                      'E-mail Address', 'E-mail 2 Address', 'E-mail 3 Address',
                      'Business Street', 'Business City', 'Business State', 'Business Postal Code', 'Business Country/Region',
                      'Home Street', 'Home City', 'Home State', 'Home Postal Code', 'Home Country/Region',
                      'Birthday', 'Notes']

        with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            for contact in contacts:
                row = {}
                if hasattr(contact, 'n'):
                    row['First Name'] = contact.n.value.given
                    row['Middle Name'] = contact.n.value.additional
                    row['Last Name'] = contact.n.value.family
                if hasattr(contact, 'org'):
                    row['Company'] = contact.org.value[0] if contact.org.value else ''
                if hasattr(contact, 'title'):
                    row['Job Title'] = contact.title.value

                email_count = 1
                for child in contact.getChildren():
                    if child.name == 'TEL':
                        if hasattr(child, 'type_param'):
                            if 'CELL' in child.type_param:
                                row['Mobile Phone'] = child.value
                            elif 'WORK' in child.type_param:
                                row['Business Phone'] = child.value
                            elif 'HOME' in child.type_param:
                                row['Home Phone'] = child.value
                        else:
                            row['Mobile Phone'] = child.value
                    elif child.name == 'EMAIL' and email_count <= 3:
                        row[f'E-mail Address' if email_count == 1 else f'E-mail {email_count} Address'] = child.value
                        email_count += 1
                    elif child.name == 'ADR':
                        if hasattr(child, 'type_param') and 'WORK' in child.type_param:
                            prefix = 'Business'
                        else:
                            prefix = 'Home'
                        row[f'{prefix} Street'] = child.value.street
                        row[f'{prefix} City'] = child.value.city
                        row[f'{prefix} State'] = child.value.region
                        row[f'{prefix} Postal Code'] = child.value.code
                        row[f'{prefix} Country/Region'] = child.value.country

                if hasattr(contact, 'bday'):
                    row['Birthday'] = contact.bday.value
                if hasattr(contact, 'note'):
                    row['Notes'] = contact.note.value

                writer.writerow(row)

    def generate_unique_filename(self, directory, base_name):
        counter = 1
        file_extension = self.get_file_extension()
        filename = f"{base_name}{file_extension}"
        while os.path.exists(os.path.join(directory, filename)):
            filename = f"{base_name}_{counter}{file_extension}"
            counter += 1
        return os.path.join(directory, filename)

    def get_file_extension(self):
        if self.output_format == "VCF":
            return ".vcf"
        else:
            return ".csv"

    def get_file_extension(self):
        if self.output_format == "VCF":
            return ".vcf"
        else:
            return ".csv"

    def sanitize_filename(self, filename):
        # Remove invalid characters from the filename
        invalid_chars = '<>:"/\\|?*'
        for char in invalid_chars:
            filename = filename.replace(char, '')
        return filename.strip()

    def log_conversion(self, input_file, output_file):
        # You can implement logging logic here if needed
        pass

    def handle_error(self, error_message):
        # You can implement error handling logic here
        print(f"Error: {error_message}")
        # You might want to emit a signal to inform the GUI about the error
        # self.error_occurred.emit(error_message)

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Contact Converter")
        self.setGeometry(100, 100, 600, 400)
        self.setStyleSheet("""
            QMainWindow, QWidget {
                background-color: #202020;
                color: #ffffff;
            }
            QPushButton {
                background-color: #0078d4;
                color: white;
                border: none;
                padding: 8px 16px;
                border-radius: 4px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #1e90ff;
            }
            QLabel {
                font-size: 14px;
            }
            QComboBox, QLineEdit, QListWidget {
                background-color: #333333;
                border: 1px solid #555555;
                border-radius: 4px;
                padding: 5px;
                color: #ffffff;
            }
            QComboBox::drop-down {
                border: none;
            }
            QComboBox::down-arrow {
                image: url(down_arrow.png);
                width: 14px;
                height: 14px;
            }
            QCheckBox {
                spacing: 5px;
            }
            QCheckBox::indicator {
                width: 18px;
                height: 18px;
            }
            QProgressBar {
                border: 1px solid #555555;
                border-radius: 4px;
                text-align: center;
            }
            QProgressBar::chunk {
                background-color: #0078d4;
            }
        """)

        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.layout = QVBoxLayout(self.central_widget)
        self.layout.setContentsMargins(20, 20, 20, 20)
        self.layout.setSpacing(15)

        self.setup_ui()

    def setup_ui(self):
        # Input section
        input_group = QGroupBox("Input")
        input_group.setStyleSheet("""
            QGroupBox {
                font-weight: bold;
                border: 1px solid #555555;
                border-radius: 4px;
                margin-top: 0.5em;
                padding-top: 0.5em;
            }
            QGroupBox::title {
                subcontrol-origin: margin;
                left: 10px;
                padding: 0 3px 0 3px;
            }
        """)
        input_layout = QVBoxLayout()
        input_layout.setSpacing(10)

        self.input_files = QListWidget()
        self.input_files.setMaximumHeight(100)
        input_layout.addWidget(QLabel("Input Files:"))
        input_layout.addWidget(self.input_files)

        file_buttons_layout = QHBoxLayout()
        add_files_btn = QPushButton("Add Files")
        add_files_btn.clicked.connect(self.add_files)
        file_buttons_layout.addWidget(add_files_btn)
        remove_file_btn = QPushButton("Remove Selected")
        remove_file_btn.clicked.connect(self.remove_selected_file)
        file_buttons_layout.addWidget(remove_file_btn)
        input_layout.addLayout(file_buttons_layout)

        input_group.setLayout(input_layout)
        self.layout.addWidget(input_group)

        # Output section
        output_group = QGroupBox("Output")
        output_group.setStyleSheet("""
            QGroupBox {
                font-weight: bold;
                border: 1px solid #555555;
                border-radius: 4px;
                margin-top: 0.5em;
                padding-top: 0.5em;
            }
            QGroupBox::title {
                subcontrol-origin: margin;
                left: 10px;
                padding: 0 3px 0 3px;
            }
        """)
        output_layout = QVBoxLayout()
        output_layout.setSpacing(10)

        self.output_format = QComboBox()
        self.output_format.addItems(["Google CSV", "Outlook CSV", "VCF"])
        output_layout.addWidget(QLabel("Output Format:"))
        output_layout.addWidget(self.output_format)

        output_dir_layout = QHBoxLayout()
        self.output_dir = QLineEdit()
        self.output_dir.setPlaceholderText("Select output directory...")
        output_dir_layout.addWidget(self.output_dir)
        select_dir_btn = QPushButton("...")
        select_dir_btn.setMaximumWidth(40)
        select_dir_btn.clicked.connect(self.select_output_dir)
        output_dir_layout.addWidget(select_dir_btn)
        output_layout.addWidget(QLabel("Output Directory:"))
        output_layout.addLayout(output_dir_layout)

        self.output_filename = QLineEdit()
        self.output_filename.setPlaceholderText("Enter output filename (without extension)")
        output_layout.addWidget(QLabel("Output Filename:"))
        output_layout.addWidget(self.output_filename)

        self.merge_files = QCheckBox("Merge all contacts into a single file")
        output_layout.addWidget(self.merge_files)

        output_group.setLayout(output_layout)
        self.layout.addWidget(output_group)

        # Convert button and progress bar
        self.convert_btn = QPushButton("Convert")
        self.convert_btn.clicked.connect(self.start_conversion)
        self.layout.addWidget(self.convert_btn)

        self.progress_bar = QProgressBar()
        self.layout.addWidget(self.progress_bar)

    def add_files(self):
        files, _ = QFileDialog.getOpenFileNames(self, "Select input files", "", "All Files (*.*)")
        for file in files:
            file_format = self.detect_file_format(file)
            if file_format:
                item = QListWidgetItem(f"{file} ({file_format})")
                item.setData(Qt.ItemDataRole.UserRole, file)
                self.input_files.addItem(item)
            else:
                QMessageBox.warning(self, "Invalid File", f"The file {file} is not a valid contact file format.")

    def remove_selected_file(self):
        for item in self.input_files.selectedItems():
            self.input_files.takeItem(self.input_files.row(item))

    def detect_file_format(self, file_path):
        _, ext = os.path.splitext(file_path)
        if ext.lower() == '.vcf':
            return "VCF"
        elif ext.lower() == '.csv':
            with open(file_path, 'r', newline='', encoding='utf-8') as csvfile:
                reader = csv.reader(csvfile)
                header = next(reader, None)
                if header:
                    if 'Given Name' in header and 'Family Name' in header:
                        return "Google CSV"
                    elif 'First Name' in header and 'Last Name' in header:
                        return "Outlook CSV"
        return None

    def select_output_dir(self):
        directory = QFileDialog.getExistingDirectory(self, "Select Output Directory")
        if directory:
            self.output_dir.setText(directory)

    def start_conversion(self):
        input_files = [self.input_files.item(i).data(Qt.ItemDataRole.UserRole) for i in range(self.input_files.count())]
        output_dir = self.output_dir.text()
        output_format = self.output_format.currentText()
        merge_files = self.merge_files.isChecked()
        output_filename = self.output_filename.text()

        if not input_files:
            QMessageBox.warning(self, "No Input Files", "Please add input files before converting.")
            return

        if not output_dir:
            QMessageBox.warning(self, "No Output Directory", "Please select an output directory.")
            return

        if not output_filename:
            QMessageBox.warning(self, "No Output Filename", "Please enter an output filename.")
            return

        # Generate output filename
        if merge_files:
            output_file = self.generate_unique_filename(output_dir, output_filename, output_format)
        else:
            output_file = output_filename  # We'll handle individual file naming in the converter

        self.converter = ContactConverter(input_files, output_dir, output_format, merge_files, output_file)
        self.converter.progress_update.connect(self.update_progress)
        self.converter.conversion_complete.connect(self.conversion_finished)
        self.converter.start()

        self.convert_btn.setEnabled(False)
        self.progress_bar.setValue(0)

    def generate_unique_filename(self, directory, base_name, format):
        extension = ".vcf" if format == "VCF" else ".csv"
        counter = 1
        filename = f"{base_name}{extension}"
        while os.path.exists(os.path.join(directory, filename)):
            filename = f"{base_name}_{counter}{extension}"
            counter += 1
        return filename

    def update_progress(self, value):
        self.progress_bar.setValue(value)

    def conversion_finished(self, output_files):
        self.progress_bar.setValue(100)
        self.convert_btn.setEnabled(True)
        if isinstance(output_files, list):
            message = f"Conversion complete. Files saved:\n" + "\n".join(output_files)
        else:
            message = f"Conversion complete. File saved as {output_files}"
        QMessageBox.information(self, "Conversion Complete", message)


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())