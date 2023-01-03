# Gambot, a chatbot for Gambit

Welcome and meet Gambot, your new friend ! Gambot is a chatbot for [Zulip](https://zulip.com/), entirely written in [Gambit](https://gambitscheme.org/) Scheme. It can be used to run Scheme programs at your fingertips when you converse with friends on Zulip. It has been created as a side project to add a bit of fun in everyday conversions at the Compilation Lab @ University of Montreal ! Try it out below !

## Run it 
### Locally
To run Gambot, clone the repository and simply do :
```
gsi ./ server.scm
```

### Docker
You can also run it with docker as such

```
docker run -it leonardool/gambot
```

### Docker compose
A simple docker-compose.yml file is present in the root of this repository. By default, the gambot server will run on 8081, but you can easily change this in the docker-compose.yml file.

```
wget https://raw.githubusercontent.com/leo-ard/gambot/main/docker-compose.yml
docker-compose up
```

## Use it

To use it, you will need a publicly available server and expose this server to the world. Once configured, you can [add it to your bots](https://zulip.com/help/add-a-bot-or-integration) in your personal settings. Make sure to choose the "outgooing webhook" type and to put your exposed server address in the url.

IMPORTANT: You must run the server inside of a docker. As the purpose of this bot is to run code, it's easy to access the internals of the server, for example by running `(shell-command "ls")`. If not containerized properlly, code execution could leak to the main server and potentially break it.


