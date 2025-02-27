import urllib.request
import gzip
import os
from multiprocessing.dummy import Pool as ThreadPool

def download_file(file_id):
    try:
        print(f"Downloading: {file_id}")    
        url = f'http://1001genomes.org/data/GMI-MPI/releases/v3.1/pseudogenomes/fasta/pseudo{file_id}.fasta.gz'
        gz_file_path = f'archive/pseudo{file_id}.fasta.gz'
        extracted_file_path = f'archive/pseudo{file_id}.fasta'

        urllib.request.urlretrieve(url, gz_file_path)


        with gzip.open(gz_file_path, 'rb') as f_in, open(extracted_file_path, 'wb') as f_out:
            for line in f_in:
                if not line.startswith(b">"):
                    f_out.write(line.strip())

        os.remove(gz_file_path)
    except Exception as e:
        print(f"Error! {file_id}: {e}")
    print(f"File {file_id} has been downloaded and extracted.")

file_ids = []
with open("all_ids.csv") as f:
    for line in f.readlines():
        index = line.replace('\n','')
        file_ids.append(index)

pool = ThreadPool(32)
pool.map(download_file, file_ids)

pool.close()
pool.join()
