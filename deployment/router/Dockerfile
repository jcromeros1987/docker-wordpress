FROM nginx:alpine

COPY nginx.conf /etc/nginx/nginx.conf
COPY certs /etc/nginx/certs
COPY includes /etc/nginx/includes
COPY sites /etc/nginx/sites

EXPOSE 80 443
