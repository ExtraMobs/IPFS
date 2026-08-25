/// Port of `multiformats/go-multiaddr-dns`.
library;

export 'src/dns_resolver.dart'
    show BasicResolver, MockResolver, Resolver, dnsMatches, fqdn, isFqdn;
