# Build image
FROM node:12.22-alpine AS build
ARG BASE_PATH
ARG DATABASE_TYPE
ENV BASE_PATH=$BASE_PATH
ENV DATABASE_URL "postgres://mekrwagpgdfsba:61cf57e88fe90eed0750a846dd39a4199587f3739ff6f179401391cc1518a85e@ec2-3-213-41-172.compute-1.amazonaws.com:5432/d9p87asdojj97t" \
    DATABASE_TYPE=$DATABASE_TYPE
WORKDIR /build

RUN yarn config set --home enableTelemetry 0
COPY package.json yarn.lock /build/

# Install only the production dependencies
RUN yarn install --production --frozen-lockfile

# Cache these modules for production
RUN cp -R node_modules/ prod_node_modules/

# Install development dependencies
RUN yarn install --frozen-lockfile

COPY . /build
RUN yarn next telemetry disable
RUN yarn build

# Production image
FROM node:12.22-alpine AS production
WORKDIR /app

# Copy cached dependencies
COPY --from=build /build/prod_node_modules ./node_modules

# Copy generated Prisma client
COPY --from=build /build/node_modules/.prisma/ ./node_modules/.prisma/

COPY --from=build /build/yarn.lock /build/package.json ./
COPY --from=build /build/.next ./.next
COPY --from=build /build/public ./public

USER node

EXPOSE 3000
CMD ["yarn", "start"]
