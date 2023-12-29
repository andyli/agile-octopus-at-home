VERSION 0.7

run.js:
    FROM haxe:4.3.3
    WORKDIR /usr/src/
    COPY build.hxml .
    RUN haxelib install ./build.hxml --always
    COPY src src
    RUN haxe build.hxml
    SAVE ARTIFACT run.js AS LOCAL run.js
