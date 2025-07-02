from plexapi.myplex import MyPlexAccount
account = MyPlexAccount('<USERNAME>', '<PASSWORD>')
plex = account.resource('<SERVERNAME>').connect()  # returns a PlexServer instance

# Example 3: List all clients connected to the Server.
for client in plex.clients():
    print(client.title)
