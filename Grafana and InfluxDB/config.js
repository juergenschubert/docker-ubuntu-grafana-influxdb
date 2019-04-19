datasources: {
        influxdb: {
          type: 'influxdb',
          url: "http://your-server-ip:8086/db/testdb",
          username: 'root',
          password: 'root',
        },
        grafana: {
          type: 'influxdb',
          url: "http://your-server-ip:8086/db/grafana",
          username: 'root',
          password: 'root',
          grafanaDB: true
        },
      },
