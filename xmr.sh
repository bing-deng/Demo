sudo apt-get update
sudo apt-get install git build-essential cmake automake libtool autoconf
git clone https://github.com/xmrig/xmrig.git
mkdir xmrig/build && cd xmrig/scripts
./build_deps.sh && cd ../build
cmake .. -DXMRIG_DEPS=scripts/deps
#cmake .. -DWITH_HWLOC=OFF
make -j$(nproc)

# balance
#./xmrig -o xmr-asia1.nanopool.org:14444 -a rx/0 -u 86TWFNfb5yE5rcfzmawiM1QbcdosMaqUcNoVQxkZ79syFCVeHufXL9G5F2ntKm6vZqHpz96V1uen3efnJaqWKBXu1aTJt2X 
./xmrig -o xmr-asia1.nanopool.org:14433 -u 86TWFNfb5yE5rcfzmawiM1QbcdosMaqUcNoVQxkZ79syFCVeHufXL9G5F2ntKm6vZqHpz96V1uen3efnJaqWKBXu1aTJt2X --tls --coin monero
