type SpotifyTokenResponse = {
  access_token: string;
  token_type: string;
  expires_in: number;
};

type SpotifySearchArtistResponse = {
  artists: {
    items: SpotifyArtist[];
  };
};

type SpotifySearchTrackResponse = {
  tracks: {
    items: SpotifyTrack[];
    total: number;
  };
};

type SpotifyArtistByIdResponse = {
  id: string;
  name: string;
};

export type SpotifyArtist = {
  id: string;
  name: string;
};

export type SpotifyTrack = {
  id: string;
  name: string;
  album: {
    name: string;
  };
  external_urls: {
    spotify: string;
  };
};

let tokenCache:
  | {
      token: string;
      expiresAtMs: number;
    }
  | undefined;

const TOKEN_EXPIRY_SKEW_MS = 60_000;

function getSpotifyCredentials(): { clientId: string; clientSecret: string } {
  const clientId = process.env.SPOTIFY_CLIENT_ID;
  const clientSecret = process.env.SPOTIFY_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    throw new Error(
      "Spotify credentials are missing. Set SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET."
    );
  }

  return { clientId, clientSecret };
}

async function fetchAccessToken(): Promise<SpotifyTokenResponse> {
  const { clientId, clientSecret } = getSpotifyCredentials();
  const authorization = Buffer.from(`${clientId}:${clientSecret}`).toString(
    "base64"
  );

  const response = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    headers: {
      Authorization: `Basic ${authorization}`,
      "Content-Type": "application/x-www-form-urlencoded"
    },
    body: "grant_type=client_credentials"
  });

  if (!response.ok) {
    const bodyText = await response.text();
    throw new Error(
      `Spotify token request failed (${response.status}): ${bodyText}`
    );
  }

  return (await response.json()) as SpotifyTokenResponse;
}

export async function getAccessToken(): Promise<string> {
  if (tokenCache && Date.now() < tokenCache.expiresAtMs - TOKEN_EXPIRY_SKEW_MS) {
    return tokenCache.token;
  }

  const tokenResponse = await fetchAccessToken();
  tokenCache = {
    token: tokenResponse.access_token,
    expiresAtMs: Date.now() + tokenResponse.expires_in * 1000
  };

  return tokenCache.token;
}

async function spotifyGet<T>(
  path: string,
  query?: Record<string, string | number | undefined>
): Promise<T> {
  const token = await getAccessToken();
  const url = new URL(`https://api.spotify.com${path}`);
  if (query) {
    for (const [key, value] of Object.entries(query)) {
      if (value !== undefined) {
        url.searchParams.set(key, String(value));
      }
    }
  }

  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${token}`
    }
  });

  if (!response.ok) {
    const bodyText = await response.text();
    throw new Error(
      `Spotify API request failed (${response.status}) at ${path}: ${bodyText}`
    );
  }

  return (await response.json()) as T;
}

export async function searchTopArtist(
  artistQuery: string
): Promise<SpotifyArtist | undefined> {
  const response = await spotifyGet<SpotifySearchArtistResponse>("/v1/search", {
    type: "artist",
    q: artistQuery,
    limit: 1,
    market: "JP"
  });

  return response.artists.items[0];
}

export async function fetchArtistById(
  artistId: string
): Promise<SpotifyArtist | undefined> {
  try {
    const response = await spotifyGet<SpotifyArtistByIdResponse>(
      `/v1/artists/${encodeURIComponent(artistId)}`
    );
    return { id: response.id, name: response.name };
  } catch {
    return undefined;
  }
}

export async function searchTracksByArtistName(
  artistName: string,
  offset: number,
  limit = 50
): Promise<{ items: SpotifyTrack[]; total: number }> {
  const response = await spotifyGet<SpotifySearchTrackResponse>("/v1/search", {
    type: "track",
    q: `artist:"${artistName}"`,
    limit,
    offset,
    market: "JP"
  });

  return {
    items: response.tracks.items,
    total: response.tracks.total
  };
}
