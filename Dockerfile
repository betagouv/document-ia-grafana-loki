FROM scalingo/scalingo-24
ADD . buildpack

ADD .env /env/.env
RUN buildpack/bin/env.sh /env/.env /env
RUN buildpack/bin/compile /build /cache /env

RUN mkdir -p /app
RUN cp -rf /build/grafana /app/grafana
RUN cp -rf /build/bin /app/bin
RUN cp -rf /build/conf /app/conf

EXPOSE 3000

ENTRYPOINT [ "/app/bin/run" ]