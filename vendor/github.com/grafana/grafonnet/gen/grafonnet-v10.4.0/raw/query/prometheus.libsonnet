// This file is generated, do not manually edit.
{
  '#': { help: 'grafonnet.query.prometheus', name: 'prometheus' },
  '#withDatasource': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: "For mixed data sources the selected datasource is on the query level.\nFor non mixed scenarios this is undefined.\nTODO find a better way to do this ^ that's friendly to schema\nTODO this shouldn't be unknown but DataSourceRef | null" } },
  withDatasource(value): {
    datasource: value,
  },
  '#withEditorMode': { 'function': { args: [{ default: null, enums: ['code', 'builder'], name: 'value', type: ['string'] }], help: '' } },
  withEditorMode(value): {
    editorMode: value,
  },
  '#withExemplar': { 'function': { args: [{ default: true, enums: null, name: 'value', type: ['boolean'] }], help: 'Execute an additional query to identify interesting raw samples relevant for the given expr' } },
  withExemplar(value=true): {
    exemplar: value,
  },
  '#withExpr': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: 'The actual expression/query that will be evaluated by Prometheus' } },
  withExpr(value): {
    expr: value,
  },
  '#withFormat': { 'function': { args: [{ default: null, enums: ['time_series', 'table', 'heatmap'], name: 'value', type: ['string'] }], help: '' } },
  withFormat(value): {
    format: value,
  },
  '#withHide': { 'function': { args: [{ default: true, enums: null, name: 'value', type: ['boolean'] }], help: 'true if query is disabled (ie should not be returned to the dashboard)\nNote this does not always imply that the query should not be executed since\nthe results from a hidden query may be used as the input to other queries (SSE etc)' } },
  withHide(value=true): {
    hide: value,
  },
  '#withInstant': { 'function': { args: [{ default: true, enums: null, name: 'value', type: ['boolean'] }], help: 'Returns only the latest value that Prometheus has scraped for the requested time series' } },
  withInstant(value=true): {
    instant: value,
  },
  '#withIntervalFactor': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['number'] }], help: '@deprecated Used to specify how many times to divide max data points by. We use max data points under query options\nSee https://github.com/grafana/grafana/issues/48081' } },
  withIntervalFactor(value): {
    intervalFactor: value,
  },
  '#withLegendFormat': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: 'Series name override or template. Ex. {{hostname}} will be replaced with label value for hostname' } },
  withLegendFormat(value): {
    legendFormat: value,
  },
  '#withQueryType': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: 'Specify the query flavor\nTODO make this required and give it a default' } },
  withQueryType(value): {
    queryType: value,
  },
  '#withRange': { 'function': { args: [{ default: true, enums: null, name: 'value', type: ['boolean'] }], help: 'Returns a Range vector, comprised of a set of time series containing a range of data points over time for each time series' } },
  withRange(value=true): {
    range: value,
  },
  '#withRefId': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: 'A unique identifier for the query within the list of targets.\nIn server side expressions, the refId is used as a variable name to identify results.\nBy default, the UI will assign A->Z; however setting meaningful names may be useful.' } },
  withRefId(value): {
    refId: value,
  },
  '#withScope': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['object'] }], help: '' } },
  withScope(value): {
    scope: value,
  },
  '#withScopeMixin': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['object'] }], help: '' } },
  withScopeMixin(value): {
    scope+: value,
  },
  scope+:
    {
      '#withMatchers': { 'function': { args: [{ default: null, enums: null, name: 'value', type: ['string'] }], help: '' } },
      withMatchers(value): {
        scope+: {
          matchers: value,
        },
      },
    },
}
