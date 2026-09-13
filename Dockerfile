FROM nginx:alpine

COPY build/web/ /usr/share/nginx/html/
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Compress once here rather than on every request; nginx serves these through
# gzip_static. -k keeps the originals for clients that do not accept gzip.
RUN find /usr/share/nginx/html -type f \
      \( -name '*.wasm' -o -name '*.js' -o -name '*.pck' -o -name '*.html' \) \
      -exec gzip -9 -k {} \;

EXPOSE 80
