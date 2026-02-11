import 'package:flutter_query/flutter_query.dart' as fq;

typedef UseQueryArgs<TData, TError> = ({
  List<Object?> queryKey,
  fq.QueryFn<TData> queryFn,

  bool? enabled,
  fq.NetworkMode? networkMode,
  fq.StaleDuration? staleDuration,
  fq.GcDuration? gcDuration,
  TData? placeholder,
  fq.RefetchOnMount? refetchOnMount,
  fq.RefetchOnResume? refetchOnResume,
  fq.RefetchOnReconnect? refetchOnReconnect,
  Duration? refetchInterval,
  fq.RetryResolver<TError>? retry,
  bool? retryOnMount,
  TData? seed,
  DateTime? seedUpdatedAt,
  Map<String, dynamic>? meta,
  fq.QueryClient? client,
});

fq.QueryResult<TData, TError> useQuery<TData, TError>(
  UseQueryArgs<TData, TError> args,
) {
  return fq.useQuery<TData, TError>(
    args.queryKey,
    args.queryFn,
    enabled: args.enabled,
    networkMode: args.networkMode,
    staleDuration: args.staleDuration,
    gcDuration: args.gcDuration,
    placeholder: args.placeholder,
    refetchOnMount: args.refetchOnMount,
    refetchOnResume: args.refetchOnResume,
    refetchOnReconnect: args.refetchOnReconnect,
    refetchInterval: args.refetchInterval,
    retry: args.retry,
    retryOnMount: args.retryOnMount,
    seed: args.seed,
    seedUpdatedAt: args.seedUpdatedAt,
    meta: args.meta,
    client: args.client,
  );
}

UseQueryArgs<TData, TError> buildQueryArgs<TData, TError>({
  required List<Object?> queryKey,
  required fq.QueryFn<TData> queryFn,

  bool? enabled,
  fq.NetworkMode? networkMode,
  fq.StaleDuration? staleDuration,
  fq.GcDuration? gcDuration,
  TData? placeholder,
  fq.RefetchOnMount? refetchOnMount,
  fq.RefetchOnResume? refetchOnResume,
  fq.RefetchOnReconnect? refetchOnReconnect,
  Duration? refetchInterval,
  fq.RetryResolver<TError>? retry,
  bool? retryOnMount,
  TData? seed,
  DateTime? seedUpdatedAt,
  Map<String, dynamic>? meta,
  fq.QueryClient? client,
}) {
  return (
    queryKey: queryKey,
    queryFn: queryFn,
    enabled: enabled,
    networkMode: networkMode,
    staleDuration: staleDuration,
    gcDuration: gcDuration,
    placeholder: placeholder,
    refetchOnMount: refetchOnMount,
    refetchOnResume: refetchOnResume,
    refetchOnReconnect: refetchOnReconnect,
    refetchInterval: refetchInterval,
    retry: retry,
    retryOnMount: retryOnMount,
    seed: seed,
    seedUpdatedAt: seedUpdatedAt,
    meta: meta,
    client: client,
  );
}
