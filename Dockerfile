FROM elixir:latest

WORKDIR /app

COPY . /app

RUN mix deps.get --only prod
RUN mix compile

CMD mix run --no-halt