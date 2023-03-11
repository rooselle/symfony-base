FROM lavoweb/php-8.2:composer

# Install Node.js (& npm)
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
    && apt-get install -y nodejs
RUN npm install --location=global npm

# Install PCOV extension for code coverage
RUN pecl install pcov && docker-php-ext-enable pcov

# Install PGSQL
RUN apt-get install -y libpq-dev
RUN docker-php-ext-install pdo_pgsql pgsql
