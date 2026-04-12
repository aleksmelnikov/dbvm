Fedora
======

Supported versions: Fedora 42, 43.

Installing Build Toolchain
--------------------------

Install the core C++ development tools:
```bash
dnf install gcc14 gcc14-c++ make autoconf gawk
```

Register gcc/g++-14:
```bash
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 14
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 14
```

Add Adoptium's repository (for Java 1.8):
```bash
dnf install adoptium-temurin-java-repository
fedora-third-party enable
```

Install Java:
```bash
dnf install temurin-8-jdk
```

Install Library Dependencies
----------------------------

Not needed. Because the specific `Flex, Bison, Re2c, Openssl, Ncurses` sources was added to the repository`/3rdparty`.

Build and Installation Instructions
-----------------------------------

Clone the repository:
```bash
git clone https://github.com/aleksmelnikov/dbvm.git
```

Build the project:
```bash
cd dbvm
./build.sh
```

Build artifacts will be located in the `dbvm/altibase_home` directory.

Running the Database
--------------------

Set up the environment:
```bash
source ./dbenv.sh
```

Create the database configuration file:
```bash
cp $ALTIBASE_HOME/conf/altibase.properties.release $ALTIBASE_HOME/conf/altibase.properties 
```

Create a new database:
```bash
$ALTIBASE_HOME/bin/server create UTF8 UTF8
```

Start the server daemon:
```bash
$ALTIBASE_HOME/bin/server start
```

Use the `ISQL` utility to connect to the server and execute a test query:
```bash
$ALTIBASE_HOME/bin/is
iSQL> select * from tab;
```
