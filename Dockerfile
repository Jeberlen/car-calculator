FROM elixir:1.12-alpine AS build

# Set the working directory
WORKDIR /app

# Install dependencies
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy the mix.exs and mix.lock files
COPY mix.exs mix.lock ./

# Install the dependencies
RUN mix deps.get

# Copy the rest of the application code
COPY . .

# Compile the application
RUN mix compile

# Build the assets
RUN cd assets && \
    npm install && \
    npm run deploy

# Create the release
RUN mix release

# Production stage
FROM elixir:1.12-alpine

# Set the working directory
WORKDIR /app

# Copy the release from the build stage
COPY --from=build /app/_build/prod/rel/my_phoenix_app ./

# Expose the port the app runs on
EXPOSE 4000

# Start the application
CMD ["bin/my_phoenix_app", "start"]