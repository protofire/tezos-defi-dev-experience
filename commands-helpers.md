# LIGO

### Compile

```bash
$ ligo compile-contract contractName.ligo main | tr -d '\r' > contractName.tz
```

### Compile storage

```bash
$ ligo compile-storage contractName.ligo main "...ligoStorage..."
```

### Compile parameter

```bash
$ ligo compile-parameter contractName.ligo -s pascaligo main "Inc(-20)"
```

### Test function

```bash
$ ligo run-function file.ligo functionName "args"
```

### Copy to docker

```bash
$ docker cp contractName.tz containerNodeName:/home/tezos
```

# Tezos-client

### Alias

```bash
$ alias babylon-client="tezos-client -A rpctest.tzbeta.net -P 443 -S -w none"
```

### Deploy

```bash
$ babylon-client originate contract contractName transferring 0 from contractOwner running contactName.tz --init "...MichelsonStorage..." --burn-cap 4.442
```

### Contract Storage

```bash
$ babylon-client get script storage for sum
```
