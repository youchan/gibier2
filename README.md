# gibier2

A slide tool inspired [Rabbit](https://rabbit-shocker.org/en/usage/rabbit-slide.html).

This is a slide app using ruby.wasm.

## Setup

Clone the repo and bundle install ruby.wasm and etc...
```sh
git clone https://github.com/youchan/gibier2
cd gibier2/wasm
bundle install
```

Build ruby.wasm including necessary gems.
```sh
bundle exec rbwasm build -o dist/ruby.wasm
```

Pack gibier2 source code into ruby.wasm
```sh
bundle exec rbwasm pack ../dist/ruby.wasm --dir ./src::/src -o ../dist/app.wasm
rake compress
```

Setup server-side
```sh
cd ..
bundle install
```

## How to run

Run gibier server
```sh
bundle exec rackup
```

Open http://localhost:9161 then you can see the sample slide.

