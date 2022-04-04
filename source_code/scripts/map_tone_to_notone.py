import json
import argparse

def create_tone_map():
  mapping = {
      'a': ['ā', 'á', 'ǎ', 'à', 'a'], 
      'e': ['ē', 'é', 'ě', 'è', 'e'],
      'i': ['ī', 'í', 'ǐ', 'ì', 'i'], 
      'o': ['ō', 'ó', 'ǒ', 'ò', 'o'], 
      'u': ['ū', 'ú', 'ǔ', 'ù', 'u'], 
      'ü': ['ǖ', 'ǘ', 'ǚ', 'ǜ', 'ü']
  }

  inv_mapping = {phn:item[0] for item in mapping.items() for phn in item[1]}
  print(inv_mapping)
  json.dump(inv_mapping, open('tone_map.json', 'w'), indent=4, sort_keys=True)
  return inv_mapping

def map_tone_to_notone(in_path, out_path):
  mapping = create_tone_map()
  with open(in_path, 'r') as f_in,\
       open(out_path, 'w') as f_out:
    for sent in f_in:
      new_sent = ''.join([mapping.get(c, c) for c in sent])
      f_out.write(new_sent)

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('--in_path')
  parser.add_argument('--out_path')
  args = parser.parse_args()
  map_tone_to_notone(args.in_path, args.out_path)
  
if __name__ == '__main__':
  main() 
