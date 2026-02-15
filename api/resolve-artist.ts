import type { VercelRequest, VercelResponse } from "@vercel/node";
import { sendError, toTrimmedString } from "./_lib/http";
import { searchTopArtist } from "./_lib/spotify";

type ResolveArtistRequestBody = {
  artistQuery?: unknown;
};

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
): Promise<void> {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    sendError(res, 405, "Method not allowed.");
    return;
  }

  try {
    const body = (req.body ?? {}) as ResolveArtistRequestBody;
    const artistQuery = toTrimmedString(body.artistQuery);

    if (!artistQuery) {
      sendError(res, 400, "artistQuery is required.");
      return;
    }

    const artist = await searchTopArtist(artistQuery);
    if (!artist) {
      sendError(
        res,
        404,
        "No artist found for that name in Spotify Japan. Try a different query."
      );
      return;
    }

    res.status(200).json({
      artistId: artist.id,
      artistDisplayName: artist.name
    });
  } catch (error) {
    const message =
      error instanceof Error
        ? error.message
        : "Unexpected error while resolving artist.";
    sendError(res, 500, message);
  }
}
