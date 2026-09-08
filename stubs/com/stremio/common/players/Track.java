package com.stremio.common.players;

import android.net.Uri;

public class Track {
    public Track(
            TrackType type,
            String id,
            Uri uri,
            String label,
            String language,
            boolean embedded,
            boolean commentary,
            boolean forced,
            String codec,
            String mime,
            Integer fourcc,
            boolean selected) {}

    public TrackType getType() {
        return null;
    }

    public String getId() {
        return null;
    }

    public Uri getUri() {
        return null;
    }

    public String getLabel() {
        return null;
    }

    public String getLanguage() {
        return null;
    }

    public boolean getEmbedded() {
        return false;
    }

    public boolean getCommentary() {
        return false;
    }

    public boolean getForced() {
        return false;
    }

    public String getCodec() {
        return null;
    }

    public String getMime() {
        return null;
    }

    public Integer getFourcc() {
        return null;
    }

    public boolean getSelected() {
        return false;
    }
}
