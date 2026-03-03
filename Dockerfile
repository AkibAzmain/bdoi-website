# Use the official Ruby image as the base
FROM ruby:3.2-slim

# Set the working directory inside the container
WORKDIR /srv/jekyll

# Install the installers
RUN apt-get update && apt-get install -y build-essential
RUN gem install bundler

# Copy the Gemfile and Gemfile.lock (if they exist) to the container
COPY Gemfile* ./

# Install dependencies specified in the Gemfile
RUN bundle install

# Expose the default Jekyll port
EXPOSE 4000

# Command to serve the Jekyll site
CMD ["bundle", "exec", "jekyll", "serve", "--host", "0.0.0.0", "--incremental"]
