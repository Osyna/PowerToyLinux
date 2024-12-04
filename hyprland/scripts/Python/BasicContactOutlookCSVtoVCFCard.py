import csv
import re
from datetime import datetime

def sanitize_phone(phone):
    return re.sub(r'[^\d+]', '', phone)

def format_date(date_str):
    if date_str:
        try:
            date_obj = datetime.strptime(date_str, '%m/%d/%Y')
            return date_obj.strftime('%Y-%m-%d')
        except ValueError:
            return ''
    return ''

def csv_to_vcf(input_file, output_file):
    with open(input_file, 'r', newline='', encoding='utf-8') as csvfile, \
         open(output_file, 'w', encoding='utf-8') as vcffile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            vcffile.write('BEGIN:VCARD\n')
            vcffile.write('VERSION:3.0\n')
            
            # Name
            last_name = row.get('Last Name', '')
            first_name = row.get('First Name', '')
            middle_name = row.get('Middle Name', '')
            vcffile.write(f'N:{last_name};{first_name};{middle_name};;;\n')
            vcffile.write(f'FN:{first_name} {middle_name} {last_name}\n')
            
            # Company and Job Title
            company = row.get('Company', '')
            job_title = row.get('Job Title', '')
            if company:
                vcffile.write(f'ORG:{company}\n')
            if job_title:
                vcffile.write(f'TITLE:{job_title}\n')
            
            # Phone numbers
            mobile = sanitize_phone(row.get('Mobile Phone', ''))
            work_phone = sanitize_phone(row.get('Business Phone', ''))
            home_phone = sanitize_phone(row.get('Home Phone', ''))
            if mobile:
                vcffile.write(f'TEL;TYPE=CELL:{mobile}\n')
            if work_phone:
                vcffile.write(f'TEL;TYPE=WORK:{work_phone}\n')
            if home_phone:
                vcffile.write(f'TEL;TYPE=HOME:{home_phone}\n')
            
            # Email addresses
            email1 = row.get('E-mail Address', '')
            email2 = row.get('E-mail 2 Address', '')
            email3 = row.get('E-mail 3 Address', '')
            if email1:
                vcffile.write(f'EMAIL;TYPE=INTERNET:{email1}\n')
            if email2:
                vcffile.write(f'EMAIL;TYPE=INTERNET:{email2}\n')
            if email3:
                vcffile.write(f'EMAIL;TYPE=INTERNET:{email3}\n')
            
            # Addresses
            work_street = row.get('Business Street', '')
            work_city = row.get('Business City', '')
            work_state = row.get('Business State', '')
            work_postal_code = row.get('Business Postal Code', '')
            work_country = row.get('Business Country/Region', '')
            if any([work_street, work_city, work_state, work_postal_code, work_country]):
                vcffile.write(f'ADR;TYPE=WORK:;;{work_street};{work_city};{work_state};{work_postal_code};{work_country}\n')
            
            home_street = row.get('Home Street', '')
            home_city = row.get('Home City', '')
            home_state = row.get('Home State', '')
            home_postal_code = row.get('Home Postal Code', '')
            home_country = row.get('Home Country/Region', '')
            if any([home_street, home_city, home_state, home_postal_code, home_country]):
                vcffile.write(f'ADR;TYPE=HOME:;;{home_street};{home_city};{home_state};{home_postal_code};{home_country}\n')
            
            # Birthday
            birthday = format_date(row.get('Birthday', ''))
            if birthday:
                vcffile.write(f'BDAY:{birthday}\n')
            
            # Notes
            notes = row.get('Notes', '')
            if notes:
                vcffile.write(f'NOTE:{notes}\n')
            
            vcffile.write('END:VCARD\n\n')

if __name__ == '__main__':
    input_file = 'contacts.csv'
    output_file = 'ios_contacts.vcf'
    csv_to_vcf(input_file, output_file)
    print(f"Conversion complete. VCF file saved as {output_file}")