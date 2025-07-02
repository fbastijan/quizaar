
FROM elixir:otp-27

# Add wait-for-it script
ADD https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh /wait-for-it.sh
RUN chmod +x /wait-for-it.sh

WORKDIR /app
COPY . .

RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get
RUN mix compile

# For dev: expose node/npm if you use assets
# RUN npm install --prefix ./assets

CMD ["mix", "phx.server"]