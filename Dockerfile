FROM leonardool/gambit:latest
COPY html#.scm html.scm http#.scm http.scm json#.scm json.scm server.scm ./
ENV PORT=1777
EXPOSE 1777
CMD gsi ./ server.scm
#RUN gsc -exe -o serv ./ server.scm
#RUN ./serv

