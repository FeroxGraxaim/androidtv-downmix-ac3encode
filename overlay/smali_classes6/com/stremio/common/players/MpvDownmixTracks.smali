.class public final Lcom/stremio/common/players/MpvDownmixTracks;
.super Ljava/lang/Object;
.source "MpvDownmixTracks.java"


# static fields
.field public static final FILTER:Ljava/lang/String; = "lavfi=[pan=stereo|FL=0.50*FL+0.85*FC+0.20*LFE+0.35*BL+0.35*SL|FR=0.50*FR+0.85*FC+0.20*LFE+0.35*BR+0.35*SR,acompressor=threshold=0.125:ratio=3:attack=20:release=250:makeup=1.5,alimiter=limit=0.95:level=0]"

.field public static final LABEL:Ljava/lang/String; = "Dialogue downmix"

.field public static final PREFIX:Ljava/lang/String; = "downmix:"

.field private static volatile enabled:Z

.field private static volatile lastTrackList:Ljava/lang/String;


# direct methods
.method private constructor <init>()V
    .registers 1

    .line 26
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


.method public static rememberTrackList(Ljava/lang/String;)V
    .registers 2

    if-eqz p0, :cond_b

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v0

    if-gtz v0, :cond_b

    sput-object p0, Lcom/stremio/common/players/MpvDownmixTracks;->lastTrackList:Ljava/lang/String;

    :cond_b
    return-void
.end method

.method public static apply(Ldev/jdtech/mpv/MPVLib;Lcom/stremio/common/players/Track;)Ljava/lang/String;
    .registers 5

    .line 63
    if-eqz p0, :cond_3c

    if-nez p1, :cond_5

    goto :goto_3c

    .line 66
    :cond_5
    invoke-virtual {p1}, Lcom/stremio/common/players/Track;->getId()Ljava/lang/String;

    move-result-object p1

    .line 67
    invoke-static {p1}, Lcom/stremio/common/players/MpvDownmixTracks;->isVirtual(Ljava/lang/String;)Z

    move-result v0

    .line 68
    invoke-static {v0}, Lcom/stremio/common/players/MpvDownmixTracks;->setEnabled(Z)V

    .line 69
    const-string v1, "aid"

    invoke-static {p1}, Lcom/stremio/common/players/MpvDownmixTracks;->sourceId(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p1

    invoke-virtual {p0, v1, p1}, Ldev/jdtech/mpv/MPVLib;->setPropertyString(Ljava/lang/String;Ljava/lang/String;)V

    .line 70
    const-string p1, "audio-channels"

    const-string v1, "af"

    if-eqz v0, :cond_31

    .line 71
    const-string v0, "ad-lavc-downmix"

    const-string v2, "no"

    invoke-virtual {p0, v0, v2}, Ldev/jdtech/mpv/MPVLib;->setPropertyString(Ljava/lang/String;Ljava/lang/String;)V

    .line 72
    const-string v0, "stereo"

    invoke-virtual {p0, p1, v0}, Ldev/jdtech/mpv/MPVLib;->setPropertyString(Ljava/lang/String;Ljava/lang/String;)V

    .line 73
    const-string p1, "lavfi=[pan=stereo|FL=0.50*FL+0.85*FC+0.20*LFE+0.35*BL+0.35*SL|FR=0.50*FR+0.85*FC+0.20*LFE+0.35*BR+0.35*SR,acompressor=threshold=0.125:ratio=3:attack=20:release=250:makeup=1.5,alimiter=limit=0.95:level=0]"

    invoke-virtual {p0, v1, p1}, Ldev/jdtech/mpv/MPVLib;->setPropertyString(Ljava/lang/String;Ljava/lang/String;)V

    goto :goto_3b

    .line 75
    :cond_31
    const-string v0, ""

    invoke-virtual {p0, v1, v0}, Ldev/jdtech/mpv/MPVLib;->setPropertyString(Ljava/lang/String;Ljava/lang/String;)V

    .line 76
    const-string v0, "auto-safe"

    invoke-virtual {p0, p1, v0}, Ldev/jdtech/mpv/MPVLib;->setPropertyString(Ljava/lang/String;Ljava/lang/String;)V

    :goto_3b
    const-string p1, "track-list"

    invoke-virtual {p0, p1}, Ldev/jdtech/mpv/MPVLib;->getPropertyString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    if-eqz p0, :cond_4d

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result p1

    if-nez p1, :cond_51

    :cond_4d
    sget-object p0, Lcom/stremio/common/players/MpvDownmixTracks;->lastTrackList:Ljava/lang/String;

    :cond_51
    return-object p0

    :cond_3c
    :goto_3c
    sget-object p0, Lcom/stremio/common/players/MpvDownmixTracks;->lastTrackList:Ljava/lang/String;

    return-object p0
.end method

.method static channelCount(Lorg/json/JSONObject;)I
    .registers 4

    .line 100
    const/4 v0, 0x0

    if-eqz p0, :cond_49

    const-string v1, "audio-channels"

    invoke-virtual {p0, v1}, Lorg/json/JSONObject;->isNull(Ljava/lang/String;)Z

    move-result v2

    if-eqz v2, :cond_c

    goto :goto_49

    .line 103
    :cond_c
    invoke-virtual {p0, v1, v0}, Lorg/json/JSONObject;->optInt(Ljava/lang/String;I)I

    move-result v2

    .line 104
    if-lez v2, :cond_13

    .line 105
    return v2

    .line 107
    :cond_13
    const-string v2, ""

    invoke-virtual {p0, v1, v2}, Lorg/json/JSONObject;->optString(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;

    move-result-object p0

    .line 108
    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v1

    if-nez v1, :cond_20

    .line 109
    return v0

    .line 112
    :cond_20
    :try_start_20
    invoke-virtual {p0}, Ljava/lang/String;->trim()Ljava/lang/String;

    move-result-object v1

    invoke-static {v1}, Ljava/lang/Integer;->parseInt(Ljava/lang/String;)I

    move-result p0
    :try_end_28
    .catch Ljava/lang/NumberFormatException; {:try_start_20 .. :try_end_28} :catch_29

    return p0

    .line 113
    :catch_29
    move-exception v1

    .line 114
    const-string v1, "7.1"

    invoke-virtual {p0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v1

    if-eqz v1, :cond_35

    .line 115
    const/16 p0, 0x8

    return p0

    .line 117
    :cond_35
    const-string v1, "5.1"

    invoke-virtual {p0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result v1

    if-nez v1, :cond_47

    const-string v1, "6.1"

    invoke-virtual {p0, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result p0

    if-eqz p0, :cond_46

    goto :goto_47

    .line 120
    :cond_46
    return v0

    .line 118
    :cond_47
    :goto_47
    const/4 p0, 0x6

    return p0

    .line 101
    :cond_49
    :goto_49
    return v0
.end method

.method static copySelected(Lcom/stremio/common/players/Track;Z)Lcom/stremio/common/players/Track;
    .registers 16

    .line 141
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getSelected()Z

    move-result v0

    if-ne v0, p1, :cond_7

    .line 142
    return-object p0

    .line 144
    :cond_7
    new-instance v1, Lcom/stremio/common/players/Track;

    .line 145
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getType()Lcom/stremio/common/players/TrackType;

    move-result-object v2

    .line 146
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getId()Ljava/lang/String;

    move-result-object v3

    .line 147
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getUri()Landroid/net/Uri;

    move-result-object v4

    .line 148
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getLabel()Ljava/lang/String;

    move-result-object v5

    .line 149
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getLanguage()Ljava/lang/String;

    move-result-object v6

    .line 150
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getEmbedded()Z

    move-result v7

    .line 151
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getCommentary()Z

    move-result v8

    .line 152
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getForced()Z

    move-result v9

    .line 153
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getCodec()Ljava/lang/String;

    move-result-object v10

    .line 154
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getMime()Ljava/lang/String;

    move-result-object v11

    .line 155
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getFourcc()Ljava/lang/Integer;

    move-result-object v12

    move v13, p1

    invoke-direct/range {v1 .. v13}, Lcom/stremio/common/players/Track;-><init>(Lcom/stremio/common/players/TrackType;Ljava/lang/String;Landroid/net/Uri;Ljava/lang/String;Ljava/lang/String;ZZZLjava/lang/String;Ljava/lang/String;Ljava/lang/Integer;Z)V

    .line 144
    return-object v1
.end method

.method public static expand(Lcom/stremio/common/players/Track;Lorg/json/JSONObject;)Ljava/util/List;
    .registers 7
    .annotation system Ldalvik/annotation/Signature;
        value = {
            "(",
            "Lcom/stremio/common/players/Track;",
            "Lorg/json/JSONObject;",
            ")",
            "Ljava/util/List<",
            "Lcom/stremio/common/players/Track;",
            ">;"
        }
    .end annotation

    .line 48
    if-nez p0, :cond_7

    .line 49
    invoke-static {}, Ljava/util/Collections;->emptyList()Ljava/util/List;

    move-result-object p0

    return-object p0

    .line 51
    :cond_7
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getType()Lcom/stremio/common/players/TrackType;

    move-result-object v0

    sget-object v1, Lcom/stremio/common/players/TrackType;->AUDIO:Lcom/stremio/common/players/TrackType;

    if-ne v0, v1, :cond_42

    invoke-static {p0, p1}, Lcom/stremio/common/players/MpvDownmixTracks;->isMultichannel(Lcom/stremio/common/players/Track;Lorg/json/JSONObject;)Z

    move-result p1

    if-nez p1, :cond_16

    goto :goto_42

    .line 54
    :cond_16
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getSelected()Z

    move-result p1

    .line 55
    invoke-static {}, Lcom/stremio/common/players/MpvDownmixTracks;->isEnabled()Z

    move-result v0

    .line 56
    new-instance v1, Ljava/util/ArrayList;

    const/4 v2, 0x2

    invoke-direct {v1, v2}, Ljava/util/ArrayList;-><init>(I)V

    .line 57
    const/4 v2, 0x1

    const/4 v3, 0x0

    if-eqz p1, :cond_2c

    if-nez v0, :cond_2c

    move v4, v2

    goto :goto_2d

    :cond_2c
    move v4, v3

    :goto_2d
    invoke-static {p0, v4}, Lcom/stremio/common/players/MpvDownmixTracks;->copySelected(Lcom/stremio/common/players/Track;Z)Lcom/stremio/common/players/Track;

    move-result-object v4

    invoke-virtual {v1, v4}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    .line 58
    if-eqz p1, :cond_39

    if-eqz v0, :cond_39

    goto :goto_3a

    :cond_39
    move v2, v3

    :goto_3a
    invoke-static {p0, v2}, Lcom/stremio/common/players/MpvDownmixTracks;->virtualTrack(Lcom/stremio/common/players/Track;Z)Lcom/stremio/common/players/Track;

    move-result-object p0

    invoke-virtual {v1, p0}, Ljava/util/ArrayList;->add(Ljava/lang/Object;)Z

    .line 59
    return-object v1

    .line 52
    :cond_42
    :goto_42
    invoke-static {p0}, Ljava/util/Collections;->singletonList(Ljava/lang/Object;)Ljava/util/List;

    move-result-object p0

    return-object p0
.end method

.method public static isEnabled()Z
    .registers 1

    .line 29
    sget-boolean v0, Lcom/stremio/common/players/MpvDownmixTracks;->enabled:Z

    return v0
.end method

.method static isMultichannel(Lcom/stremio/common/players/Track;Lorg/json/JSONObject;)Z
    .registers 4

    .line 81
    invoke-static {p1}, Lcom/stremio/common/players/MpvDownmixTracks;->channelCount(Lorg/json/JSONObject;)I

    move-result p1

    .line 82
    const/4 v0, 0x2

    const/4 v1, 0x1

    if-le p1, v0, :cond_9

    .line 83
    return v1

    .line 85
    :cond_9
    const/4 v0, 0x0

    if-lez p1, :cond_d

    .line 86
    return v0

    .line 88
    :cond_d
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getCodec()Ljava/lang/String;

    move-result-object p0

    .line 89
    if-nez p0, :cond_14

    .line 90
    return v0

    .line 92
    :cond_14
    sget-object p1, Ljava/util/Locale;->ROOT:Ljava/util/Locale;

    invoke-virtual {p0, p1}, Ljava/lang/String;->toLowerCase(Ljava/util/Locale;)Ljava/lang/String;

    move-result-object p0

    .line 93
    const-string p1, "dts"

    invoke-virtual {p0, p1}, Ljava/lang/String;->indexOf(Ljava/lang/String;)I

    move-result p1

    if-gez p1, :cond_3d

    .line 94
    const-string p1, "truehd"

    invoke-virtual {p0, p1}, Ljava/lang/String;->indexOf(Ljava/lang/String;)I

    move-result p1

    if-gez p1, :cond_3d

    .line 95
    const-string p1, "eac3"

    invoke-virtual {p0, p1}, Ljava/lang/String;->indexOf(Ljava/lang/String;)I

    move-result p1

    if-gez p1, :cond_3d

    .line 96
    const-string p1, "atmos"

    invoke-virtual {p0, p1}, Ljava/lang/String;->indexOf(Ljava/lang/String;)I

    move-result p0

    if-ltz p0, :cond_3b

    goto :goto_3d

    :cond_3b
    move v1, v0

    goto :goto_3e

    :cond_3d
    :goto_3d
    nop

    .line 93
    :goto_3e
    return v1
.end method

.method public static isVirtual(Ljava/lang/String;)Z
    .registers 2

    .line 37
    if-eqz p0, :cond_c

    const-string v0, "downmix:"

    invoke-virtual {p0, v0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z

    move-result p0

    if-eqz p0, :cond_c

    const/4 p0, 0x1

    goto :goto_d

    :cond_c
    const/4 p0, 0x0

    :goto_d
    return p0
.end method

.method public static setEnabled(Z)V
    .registers 1

    .line 33
    sput-boolean p0, Lcom/stremio/common/players/MpvDownmixTracks;->enabled:Z

    .line 34
    return-void
.end method

.method public static sourceId(Ljava/lang/String;)Ljava/lang/String;
    .registers 2

    .line 41
    invoke-static {p0}, Lcom/stremio/common/players/MpvDownmixTracks;->isVirtual(Ljava/lang/String;)Z

    move-result v0

    if-eqz v0, :cond_11

    .line 42
    const-string v0, "downmix:"

    invoke-virtual {v0}, Ljava/lang/String;->length()I

    move-result v0

    invoke-virtual {p0, v0}, Ljava/lang/String;->substring(I)Ljava/lang/String;

    move-result-object p0

    return-object p0

    .line 44
    :cond_11
    return-object p0
.end method

.method static virtualTrack(Lcom/stremio/common/players/Track;Z)Lcom/stremio/common/players/Track;
    .registers 15

    .line 125
    new-instance v0, Lcom/stremio/common/players/Track;

    .line 126
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getType()Lcom/stremio/common/players/TrackType;

    move-result-object v1

    new-instance v2, Ljava/lang/StringBuilder;

    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V

    const-string v3, "downmix:"

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    .line 127
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getId()Ljava/lang/String;

    move-result-object v3

    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    move-result-object v2

    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object v2

    .line 128
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getUri()Landroid/net/Uri;

    move-result-object v3

    .line 130
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getLanguage()Ljava/lang/String;

    move-result-object v5

    .line 131
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getEmbedded()Z

    move-result v6

    .line 132
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getCommentary()Z

    move-result v7

    .line 133
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getForced()Z

    move-result v8

    .line 134
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getCodec()Ljava/lang/String;

    move-result-object v9

    .line 135
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getMime()Ljava/lang/String;

    move-result-object v10

    .line 136
    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getFourcc()Ljava/lang/Integer;

    move-result-object v11

    invoke-static {p0}, Lcom/stremio/common/players/MpvDownmixTracks;->virtualLabel(Lcom/stremio/common/players/Track;)Ljava/lang/String;

    move-result-object v4

    move v12, p1

    invoke-direct/range {v0 .. v12}, Lcom/stremio/common/players/Track;-><init>(Lcom/stremio/common/players/TrackType;Ljava/lang/String;Landroid/net/Uri;Ljava/lang/String;Ljava/lang/String;ZZZLjava/lang/String;Ljava/lang/String;Ljava/lang/Integer;Z)V

    .line 125
    return-object v0
.end method

.method public static clear(Ldev/jdtech/mpv/MPVLib;)V
    .registers 3

    const/4 v0, 0x0

    sput-boolean v0, Lcom/stremio/common/players/MpvDownmixTracks;->enabled:Z

    if-nez p0, :cond_8

    return-void

    :cond_8
    const-string v0, "af"

    const-string v1, ""

    invoke-virtual {p0, v0, v1}, Ldev/jdtech/mpv/MPVLib;->setPropertyString(Ljava/lang/String;Ljava/lang/String;)V

    const-string v0, "audio-channels"

    const-string v1, "auto-safe"

    invoke-virtual {p0, v0, v1}, Ldev/jdtech/mpv/MPVLib;->setPropertyString(Ljava/lang/String;Ljava/lang/String;)V

    return-void
.end method

.method static virtualLabel(Lcom/stremio/common/players/Track;)Ljava/lang/String;
    .registers 3

    invoke-virtual {p0}, Lcom/stremio/common/players/Track;->getLabel()Ljava/lang/String;

    move-result-object p0

    if-eqz p0, :cond_20

    invoke-virtual {p0}, Ljava/lang/String;->length()I

    move-result v0

    if-eqz v0, :cond_20

    new-instance v0, Ljava/lang/StringBuilder;

    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V

    invoke-virtual {v0, p0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    const-string v1, " (Dialogue downmix)"

    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;

    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;

    move-result-object p0

    return-object p0

    :cond_20
    const-string p0, "Dialogue downmix"

    return-object p0
.end method
