from plexapi.server import PlexServer
baseurl = 'http://plexserver:32400'
token = '2ffLuB84dqLswk9skLos'
plex = PlexServer(baseurl, token)

# Example 3: List all clients connected to the Server.
for client in plex.clients():
    print(client.title)
