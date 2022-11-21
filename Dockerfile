FROM node:18-alpine3.16 AS build

WORKDIR /dockerbuild
COPY . .

RUN yarn install \
    && yarn build \
    && rm -rf /dockerbuild/lib/scripts

FROM node:18-alpine3.16

# "localhost" doesn't mean much in a container, so we adjust our default to the common service name "mongo" instead
# (and make sure the server listens outside the container, since "localhost" inside the container is usually difficult to access)
ARG ME_CONFIG_MONGODB_URL=$ME_CONFIG_MONGODB_URL
ARG ME_CONFIG_MONGODB_ENABLE_ADMIN=$ME_CONFIG_MONGODB_ENABLE_ADMIN
ARG ME_CONFIG_MONGODB_SSL=$ME_CONFIG_MONGODB_SSL
ARG ME_CONFIG_SITE_COOKIESECRET=$ME_CONFIG_SITE_COOKIESECRET
ARG ME_CONFIG_SITE_SESSIONSECRET=$ME_CONFIG_SITE_SESSIONSECRET
ARG ME_CONFIG_BASICAUTH=$ME_CONFIG_BASICAUTH
ARG ME_CONFIG_BASICAUTH_USERNAME=$ME_CONFIG_BASICAUTH_USERNAME
ARG ME_CONFIG_BASICAUTH_PASSWORD=$ME_CONFIG_BASICAUTH_PASSWORD
ARG MONGOexpressPort=$MONGOexpressPort
#ENV
ENV ME_CONFIG_MONGODB_URL=$ME_CONFIG_MONGODB_URL
ENV ME_CONFIG_MONGODB_ENABLE_ADMIN=$ME_CONFIG_MONGODB_ENABLE_ADMIN
ENV ME_CONFIG_MONGODB_SSL=$ME_CONFIG_MONGODB_SSL
ENV ME_CONFIG_SITE_COOKIESECRET=$ME_CONFIG_SITE_COOKIESECRET
ENV ME_CONFIG_SITE_SESSIONSECRET=$ME_CONFIG_SITE_SESSIONSECRET
ENV ME_CONFIG_BASICAUTH=$ME_CONFIG_BASICAUTH
ENV ME_CONFIG_BASICAUTH_USERNAME=$ME_CONFIG_BASICAUTH_USERNAME
ENV ME_CONFIG_BASICAUTH_PASSWORD=$ME_CONFIG_BASICAUTH_PASSWORD
ENV MONGOexpressPort=$MONGOexpressPort

ENV VCAP_APP_HOST="0.0.0.0"

WORKDIR /opt/mongo-express

COPY --from=build /dockerbuild/build /opt/mongo-express/build/
COPY --from=build /dockerbuild/public /opt/mongo-express/public/
COPY --from=build /dockerbuild/lib /opt/mongo-express/lib/
COPY --from=build /dockerbuild/app.js /opt/mongo-express/
COPY --from=build /dockerbuild/config.default.js /opt/mongo-express/
COPY --from=build /dockerbuild/*.json /opt/mongo-express/
COPY --from=build /dockerbuild/.yarn /opt/mongo-express/.yarn/
COPY --from=build /dockerbuild/yarn.lock /opt/mongo-express/
COPY --from=build /dockerbuild/.yarnrc.yml /opt/mongo-express/
COPY --from=build /dockerbuild/.npmignore /opt/mongo-express/

RUN apk -U add --no-cache \
        bash=5.1.16-r2 \
        tini=0.19.0-r0 \
    && yarn workspaces focus --production

EXPOSE 8081

CMD ["/sbin/tini", "--", "yarn", "start"]
