backend default {
  .host = "127.0.0.1";
  .port = "3000";
}

sub vcl_fetch {
    # キャッシュのTTLはここで設定したほうがよさそう
    set beresp.ttl = 120s;
    return (deliver);
}

acl purge {
  "localhost";
  "127.0.0.1";
}

sub vcl_recv {

  if(req.request == "GET") {
    return (lookup);
  }
  if(req.url ~ "^/\?") {
    return (lookup);
  }

  # PURGE
  if (req.request == "PURGE") {
    if (!client.ip ~ purge) {
      error 405 "Not allowed. (vcl_hit)";
    }
    # set req.request = "GET";
    # set req.hash_always_miss = true;
    return (lookup);
  }

  # 普通のBAN
  #if (req.request == "BAN") {
  #  if (!client.ip ~ purge) {
  #    error 405 "Not allowed. (BAN)";
  #  }

  #  ban("req.url == " + req.url);

  #  # Throw a synthetic page so the
  #  # request won't go to the backend.
  #  error 200 "Ban added";
  #}

  # SmartBan
  #if (req.request == "BAN") {
  #  ban("req.url ~ ^/$");
  #  ban("req.url ~ ^/artist/.*$");
  #  ban("req.url ~ ^/ticket/.*$");
  #  error 200 "Banned.";
  #}

}

sub vcl_hit {
  if (req.request == "PURGE") {
      purge;
      error 200 "Purged(vcl_hit)";
  }
}

sub vcl_miss {
  if (req.request == "PURGE") {
      purge;
      error 200 "Not in Cache(vcl_miss)";
  }
  set req.http.host = req.http.X-ORIGINAL-HOST;
}
