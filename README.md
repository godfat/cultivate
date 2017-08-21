# Installation

``` shell
brew install ruby sqlite
gem install sequel sqlite3
```

# Convert Big5 to UTF-8

``` shell
./bin/big5-to-utf8 path-to-csv-file-or-directory
```

# Import data

``` shell
./bin/import path-to-csv-file-or-directory
```

# Browse data

``` shell
sqlite db/db.sqlite
```
