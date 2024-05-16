FROM debian:bookworm-slim

SHELL ["/bin/bash","-l","-c"]

ENV DEBIAN_FRONTEND=noninteractive

# Libs

RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y libclang-dev

RUN apt-get install ghostscript shared-mime-info openssl curl gnupg2 dirmngr git-core libcurl4-openssl-dev software-properties-common zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libffi-dev libpq-dev libmagickcore-6.q16-dev -y

# Rust

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && chmod +x $HOME/.cargo/bin/rustc

# Ruby (rbenv)

RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv
RUN echo 'export PATH="~/.rbenv/bin:$PATH"' >> ~/.bashrc
RUN echo 'eval "$(rbenv init -)"' >> ~/.bashrc

RUN git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
RUN echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc

ENV PATH="${HOME}/.rbenv/plugins/ruby-build/bin:${HOME}/.rbenv/bin:${PATH}"

RUN rbenv install 3.3.6
RUN rbenv global 3.3.6

# Benchmark

WORKDIR /app

COPY . .

RUN bundle config set without 'jekyll-plugins' && bundle install
RUN bundle exec rake clobber compile

ENV PATH="/root/.cargo/bin:${PATH}"
RUN cd rust_graphql_parser && bundle install && bundle exec rake clobber compile && cd ..
CMD ["/root/.rbenv/shims/bundle", "exec", "ruby", "--yjit", "/app/benchmark/parser_benchmark.rb"]
