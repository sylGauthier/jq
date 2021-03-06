## jq: A journal manager

jq allows to keep a potentially encrypted journal, by using a plain and simple
folder structure to store the entries.

### Usage

**jq init** : set the gpg key-id for encrypting. Leave blank if you don't want the
journal to be encrypted.

**jq add** : open the text editor in $EDITOR variable to write an entry. Then
encrypt the file (if need be) and add it to the journal.

**jq add *filename* \[*name*\]** : add a file to the journal. Will be encrypted if
the GPG key-id has been set. The file will have the same name (+ .gpg extension
if encrypted) or the name given in second parameter.
  
**jq read \[*date*\]** : will read all the entries at the given date. If no date
given, will read all the entries in the journal. The date can be YYYY (all the
entries at the given year), YYYY/MM (same restricted to the given month) or
YYYY/MM/DD (all the entries at a given day).
  
**jq open *filename*** : decrypt (if need be) and open (with xdg-open) the given
file. Filename will be like YYYY/MM/DD/filename\[.gpg\]. When closing the reader,
the temporary decrypted file will be shredded and removed from disk.
  
**jq ls** : list all entries in tree format.
