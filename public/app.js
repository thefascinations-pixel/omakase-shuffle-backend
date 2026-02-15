const STORAGE_KEYS = {
  artistQuery: "artistQuery",
  spotifyArtistId: "spotifyArtistId",
  artistDisplayName: "artistDisplayName",
};

const state = {
  savedArtist: loadSavedArtist(),
  isResolvingArtist: false,
  isFindingTrack: false,
  lastResolvedQuery: "",
  debounceTimer: null,
};

const elements = {
  artistScreen: document.getElementById("artist-screen"),
  mainScreen: document.getElementById("main-screen"),
  artistInput: document.getElementById("artist-input"),
  artistStatus: document.getElementById("artist-status"),
  artistError: document.getElementById("artist-error"),
  displayArtist: document.getElementById("display-artist"),
  pickButton: document.getElementById("pick-button"),
  trackStatus: document.getElementById("track-status"),
  trackResult: document.getElementById("track-result"),
  trackName: document.getElementById("track-name"),
  albumName: document.getElementById("album-name"),
  spotifyLink: document.getElementById("spotify-link"),
  trackError: document.getElementById("track-error"),
  changeArtistButton: document.getElementById("change-artist-button"),
};

setupListeners();
render();

function setupListeners() {
  elements.artistInput.value = state.savedArtist?.artistQuery ?? "";
  elements.artistInput.focus();

  elements.artistInput.addEventListener("input", (event) => {
    const newValue = event.target.value;
    scheduleDebouncedSave(newValue);
  });

  elements.artistInput.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      saveArtistImmediately();
    }
  });

  elements.artistInput.addEventListener("blur", () => {
    saveArtistImmediately();
  });

  elements.pickButton.addEventListener("click", async () => {
    await pickRandomSong();
  });

  elements.changeArtistButton.addEventListener("click", () => {
    clearArtistSelection();
  });
}

function scheduleDebouncedSave(query) {
  if (state.debounceTimer) {
    window.clearTimeout(state.debounceTimer);
  }

  const trimmed = query.trim();
  if (!trimmed) {
    return;
  }

  state.debounceTimer = window.setTimeout(async () => {
    await resolveAndSaveArtist(query);
  }, 800);
}

function saveArtistImmediately() {
  if (state.debounceTimer) {
    window.clearTimeout(state.debounceTimer);
    state.debounceTimer = null;
  }
  void resolveAndSaveArtist(elements.artistInput.value);
}

async function resolveAndSaveArtist(query) {
  const trimmedQuery = query.trim();
  if (!trimmedQuery || state.isResolvingArtist) {
    return;
  }

  if (
    trimmedQuery === state.lastResolvedQuery &&
    state.savedArtist?.artistQuery === trimmedQuery
  ) {
    renderMainScreen();
    clearArtistError();
    return;
  }

  state.isResolvingArtist = true;
  clearArtistError();
  render();

  try {
    const response = await requestJSON("/api/resolve-artist", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ artistQuery: trimmedQuery }),
    });

    const artist = {
      artistQuery: trimmedQuery,
      spotifyArtistId: response.artistId,
      artistDisplayName: response.artistDisplayName,
    };

    state.savedArtist = artist;
    state.lastResolvedQuery = trimmedQuery;
    saveArtistToStorage(artist);
    clearTrackResult();
    renderMainScreen();
  } catch (error) {
    setArtistError(error.message || "Network request failed.");
  } finally {
    state.isResolvingArtist = false;
    render();
  }
}

async function pickRandomSong() {
  if (!state.savedArtist || state.isFindingTrack) {
    return;
  }

  state.isFindingTrack = true;
  clearTrackError();
  clearTrackResult();
  render();

  try {
    const params = new URLSearchParams({
      artistQuery: state.savedArtist.artistQuery,
    });
    if (state.savedArtist.spotifyArtistId) {
      params.set("artistId", state.savedArtist.spotifyArtistId);
    }

    const track = await requestJSON(`/api/random-track?${params.toString()}`);
    setTrackResult(track);
  } catch (error) {
    setTrackError(error.message || "Network request failed.");
  } finally {
    state.isFindingTrack = false;
    render();
  }
}

function clearArtistSelection() {
  window.localStorage.removeItem(STORAGE_KEYS.artistQuery);
  window.localStorage.removeItem(STORAGE_KEYS.spotifyArtistId);
  window.localStorage.removeItem(STORAGE_KEYS.artistDisplayName);

  state.savedArtist = null;
  state.lastResolvedQuery = "";
  clearArtistError();
  clearTrackError();
  clearTrackResult();
  elements.artistInput.value = "";
  renderArtistScreen();
  render();
  elements.artistInput.focus();
}

function saveArtistToStorage(artist) {
  window.localStorage.setItem(STORAGE_KEYS.artistQuery, artist.artistQuery);
  window.localStorage.setItem(
    STORAGE_KEYS.spotifyArtistId,
    artist.spotifyArtistId || "",
  );
  window.localStorage.setItem(
    STORAGE_KEYS.artistDisplayName,
    artist.artistDisplayName || "",
  );
}

function loadSavedArtist() {
  const artistQuery = window.localStorage.getItem(STORAGE_KEYS.artistQuery);
  const spotifyArtistId = window.localStorage.getItem(
    STORAGE_KEYS.spotifyArtistId,
  );
  const artistDisplayName = window.localStorage.getItem(
    STORAGE_KEYS.artistDisplayName,
  );

  if (!artistQuery || !spotifyArtistId) {
    return null;
  }

  return {
    artistQuery,
    spotifyArtistId,
    artistDisplayName: artistDisplayName || artistQuery,
  };
}

function setTrackResult(track) {
  elements.trackName.textContent = track.trackName;
  elements.albumName.textContent = track.albumName;
  elements.spotifyLink.href = track.spotifyUrl;
  elements.trackResult.hidden = false;
}

function clearTrackResult() {
  elements.trackResult.hidden = true;
  elements.trackName.textContent = "";
  elements.albumName.textContent = "";
  elements.spotifyLink.href = "#";
}

function setArtistError(message) {
  elements.artistError.textContent = message;
  elements.artistError.hidden = false;
}

function clearArtistError() {
  elements.artistError.textContent = "";
  elements.artistError.hidden = true;
}

function setTrackError(message) {
  elements.trackError.textContent = message;
  elements.trackError.hidden = false;
}

function clearTrackError() {
  elements.trackError.textContent = "";
  elements.trackError.hidden = true;
}

function renderArtistScreen() {
  elements.artistScreen.hidden = false;
  elements.mainScreen.hidden = true;
}

function renderMainScreen() {
  elements.artistScreen.hidden = true;
  elements.mainScreen.hidden = false;
}

function render() {
  if (state.savedArtist) {
    renderMainScreen();
    elements.displayArtist.textContent =
      state.savedArtist.artistDisplayName || state.savedArtist.artistQuery;
  } else {
    renderArtistScreen();
  }

  elements.artistStatus.hidden = !state.isResolvingArtist;
  elements.trackStatus.hidden = !state.isFindingTrack;
  elements.pickButton.disabled = state.isFindingTrack;
}

async function requestJSON(url, options) {
  const response = await fetch(url, options);
  const payload = await response.json().catch(() => ({}));

  if (response.ok) {
    return payload;
  }

  const fallback = response.statusText || "Request failed";
  throw new Error(payload.error || fallback);
}
