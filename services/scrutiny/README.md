# Scrutiny

Scrutiny is a tool for monitoring SMART data.

## Issues

Scrutiny uses an ancient version of smartmontools. As such, some of my new Seagate drives cannot read command timeout properly.

An apparent fix is outlined [in an issue](https://github.com/AnalogJ/scrutiny/issues/522#issuecomment-2807689281).

```sh
# copy to services/scrutiny/drivedb.h, i suppose
wget https://raw.githubusercontent.com/smartmontools/smartmontools/refs/heads/master/smartmontools/drivedb.h
```
