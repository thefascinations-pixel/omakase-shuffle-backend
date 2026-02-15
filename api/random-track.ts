import type { VercelRequest, VercelResponse } from "@vercel/node";
import { getQueryValue, sendError, toTrimmedString } from "./_lib/http";
import {
  fetchArtistById,
  searchTopArtist,
  searchTracksByArtistName,
  type SpotifyTrack
} from "./_lib/spotify";

const MAX_UNIQUE_TRACKS = 200;
const PAGE_SIZE = 20;
const MAX_OFFSET = 1000;

function pickRandomTrack(tracks: SpotifyTrack[]): SpotifyTrack {
  const index = Math.floor(Math.random() * tracks.length);
  return tracks[index];
}

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
): Promise<void> {
  if (req.method !== "GET") {
    res.setHeader("Allow", "GET");
    sendError(res, 405, "Method not allowed.");
    return;
  }

  try {
    const artistQuery = toTrimmedString(getQueryValue(req.query.artistQuery));
    const artistId = toTrimmedString(getQueryValue(req.query.artistId));

    if (!artistQuery && !artistId) {
      sendError(res, 400, "artistQuery or artistId is required.");
      return;
    }

    let resolvedArtistName = "";
    if (artistQuery) {
      const topArtist = await searchTopArtist(artistQuery);
      if (!topArtist) {
        sendError(
          res,
          404,
          "No artist found for that name in Spotify Japan. Try a different query."
        );
        return;
      }
      resolvedArtistName = topArtist.name;
    } else {
      const artist = await fetchArtistById(artistId);
      if (!artist) {
        sendError(res, 404, "Artist not found.");
        return;
      }
      resolvedArtistName = artist.name;
    }

    const seenTrackIds = new Set<string>();
    const tracksPool: SpotifyTrack[] = [];

    let offset = 0;
    let knownTotal = Number.POSITIVE_INFINITY;
    while (
      tracksPool.length < MAX_UNIQUE_TRACKS &&
      offset < MAX_OFFSET &&
      offset < knownTotal
    ) {
      const page = await searchTracksByArtistName(
        resolvedArtistName,
        offset
      );
      knownTotal = page.total;

      for (const track of page.items) {
        if (!seenTrackIds.has(track.id)) {
          seenTrackIds.add(track.id);
          tracksPool.push(track);
          if (tracksPool.length >= MAX_UNIQUE_TRACKS) {
            break;
          }
        }
      }

      if (page.items.length === 0) {
        break;
      }
      offset += PAGE_SIZE;
    }

    if (tracksPool.length === 0) {
      sendError(
        res,
        404,
        "No tracks were found for this artist in Spotify Japan."
      );
      return;
    }

    const track = pickRandomTrack(tracksPool);
    res.status(200).json({
      trackName: track.name,
      albumName: track.album.name,
      spotifyUrl: track.external_urls.spotify
    });
  } catch (error) {
    const message =
      error instanceof Error
        ? error.message
        : "Unexpected error while fetching a random track.";
    sendError(res, 500, message);
  }
}
