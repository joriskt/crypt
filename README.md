# crypt

A collection of a few personal cryptography-related bash scripts.

- [Dependencies](#dependencies)
- [Key generation](#key-generation)
    - [keygen](#keygen)
- [Key splitting](#key-splitting)
    - [keysplit](#keysplit)
    - [keymerge](#keymerge)
- [File parity archives](#file-parity-archives)
    - [parcreate](#parcreate)
    - [parrepair](#parrepair)
- [Encryption & decryption](#encryption-decryption)
    - [encrypt](#encrypt)
    - [decrypt](#decrypt)

## Dependencies

At the time of writing, the current dependencies were used:
```
ssss 0.5.7-1
par2cmdline 0.8.1-1
openssl 1.1.1.l-1
```

To install (on Arch Linux):
```
$ sudo pacman -S ssss par2cmdline openssl
```

## Key generation
Prior to encryption, a secure cryptographic key should be generated. For this, you can use the `keygen` script.

### keygen
Generates a 256-bit key + 128-bits initialization vector and stores it in the given file. This key can be used to encrypt/decrypt AES-256 files.

#### Dependencies
- none

#### Usage
To generate a 256-bit key + 128-bit IV and store it in a file called `mykey`:
```
$ ./keygen mykey
```

## Key splitting and merging
To increase the physical security of having a cryptographic key in a single location, you can use Shamir Secret Sharing to split the file into `m`-of-`n` parts. This means that the file will be split into `n` parts, with a threshold of `m` parts being required to reconstruct the original.

So, if you have a 2-of-4 split, there will be 4 unique parts, but only 2 are required to reconstruct the original.

### keysplit
Splits a key (or any file, really) into multiple parts using Shamir Secret Sharing. Both the number of parts and the threshold are configurable.

#### Dependencies
- `ssss`

#### Usage

To split the file "mykey" into 4 parts, with a threshold of 2 parts required to re-merge them:
```
$ ./keysplit mykey 2 4
```
This will create 4 files, of which you need only 2 to reconstruct the original:
```
mykey.1
mykey.2
mykey.3
mykey.4
```

### keymerge
Merges files that were split using `keysplit`. You _do_ need to know the threshold amount, although trial and error might work just fine if you don't know for sure.

#### Dependencies
- `ssss`

#### Usage
Continuing the example from [keysplit](#keysplit), given that you have for example parts `mykey.1` and `mykey.4` (with a threshold of 2 parts needed to reconstruct the original):
```
$ ./keymerge mykey
```
This will detect the parts and reconstruct the `mykey` file.

## File parity archives
To counteract data corruption and bitrot, [file parity archives](https://en.wikipedia.org/wiki/Parchive) can be used. These archives store parity data to allow the original file to be restored in case of partial corruption.

### parcreate
Creates a parity archive of your file with an optional redudancy multiplier, defaulting to 200%.

#### Dependencies
- `par2cmdline`

#### Usage
Given you have the file `mykey.1` that you want to protect with 400% redundancy:
```
$ ./parcreate mykey.1 4
```
This will create several files. Make sure to keep **all** of them, __including the original__, to actually achieve the redundancy percentage.

### parrepair
Repairs a file that has been previously created using [parcreate](#parcreate).

#### Dependencies
- `par2cmdline`

#### Usage
Continuing the example from [parcreate](#parcreate) where we created a parity archive of `mykey.1`, we expect several files:
```
$ ls -la
-rw-r--r-- 1 joris joris  195 Nov 29 21:23 mykey.1
-rw-r--r-- 1 joris joris 1384 Nov 29 21:24 mykey.1.par2
-rw-r--r-- 1 joris joris 4448 Nov 29 21:24 mykey.1.vol00+7.par2
-rw-r--r-- 1 joris joris 4448 Nov 29 21:24 mykey.1.vol07+7.par2
-rw-r--r-- 1 joris joris 4448 Nov 29 21:24 mykey.1.vol14+7.par2
-rw-r--r-- 1 joris joris 4448 Nov 29 21:24 mykey.1.vol21+7.par2
-rw-r--r-- 1 joris joris 4448 Nov 29 21:24 mykey.1.vol28+7.par2
-rw-r--r-- 1 joris joris 4376 Nov 29 21:24 mykey.1.vol35+6.par2
```
**Important:** If either the original file or the `.par2` file is missing prior to running `parrepair`, you must create them first:
```
$ touch mykey.1
$ touch mykey.1.par2
```

Once you're sure either the original file or `.par2` file exists, you can attempt to restore the data:
```
$ ./parrepair mykey.1
```

## Encryption & decryption
Some quickhand utilities to encrypt and decrypt files or streams.

### encrypt
Encrypts a file or stream with AES-256 in cipher block chaining (`aes-256-cbc`) mode.

#### Dependencies
- `openssl`

#### Usage
To encrypt a file:
```
$ ./encrypt mykey inputfile outputfile
```
To encrypt a stream:
```
$ cat inputfile | ./encrypt mykey > outputfile
```

### decrypt
Decrypts a file or stream with AES-256 in cipher block chaining (`aes-256-cbc`) mode.

#### Dependencies
- `openssl`

#### Usage
To decrypt a file:
```
$ ./decrypt mykey inputfile outputfile
```
To decrypt a stream:
```
$ cat inputfile | ./decrypt mykey > outputfile
```
