# Installing xdelta3

```bash
# osx
brew install xdelta

# ubuntu/debian
apt-get install xdelta3
```

## Example message

Example `message.text` is the lorem ipsum text.
Generated on https://www.lipsum.com

## Encoding

```bash
xdelta3 -e -s dictionary.text message.[format] message.[format].delta
```

In the examples below, `dictionary.text` is a dictionary file.
We encode `message.json`. `message.json.delta` is a delta.

#### Text

```bash
xdelta3 -e -s dictionary.text message.text message.text.delta
```

#### JSON

```bash
xdelta3 -e -s dictionary.text message.json message.json.delta
```

#### Base64

```bash
xdelta3 -e -s dictionary.text message.base64 message.base64.delta
```

#### AES 128 CBC

```bash
xdelta3 -e -s dictionary.text message.aes-128-cbc message.aes-128-cbc.delta
```

## Decoding

```bash
xdelta3 -d -s dictionary.text message.[format].delta message.decoded.[format]
```

#### Text

```bash
xdelta3 -d -s dictionary.text message.text.delta message.decoded.text
```

#### JSON

```bash
xdelta3 -d -s dictionary.text message.json.delta message.decoded.json
```

#### Base64

```bash
xdelta3 -d -s dictionary.text message.base64.delta message.decoded.base64
```

#### AES 128 CBC

```bash
xdelta3 -d -s dictionary.text message.aes-128-cbc.delta message.decoded.aes-128-cbc
```
