# FakeHTTP-Docker

Docker container for [FakeHTTP](https://github.com/MikeWang000000/FakeHTTP).


## Quick Start

```sh
docker run --rm \
    --net=host \
    --cap-add CAP_NET_ADMIN \
    --cap-add CAP_NET_RAW \
    --cap-add CAP_SYS_MODULE \
    --cap-add CAP_SYS_NICE \
    nattertool/fakehttp -h www.example.com -i eth0
```


## License

GNU General Public License v3.0
