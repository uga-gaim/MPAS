mport cdsapi

c = cdsapi.Client()

c.retrieve(
    'reanalysis-era5-pressure-levels',
    {
     	'product_type': 'reanalysis',
        'format': 'grib',
        'variable': [
            'geopotential', 
            'relative_humidity', 
            'specific_humidity',
            'temperature', 
            'u_component_of_wind', 
            'v_component_of_wind',
        ],
	'pressure_level': [
            '1', '2', '3', '5', '7', '10', '20', '30', '50', '70', 
            '100', '125', '150', '175', '200', '225', '250', '300', 
            '350', '400', '450', '500', '550', '600', '650', '700', 
            '750', '775', '800', '825', '850', '875', '900', '925', 
            '950', '975', '1000',
        ],
	'year': '2017',
        'month': '09',
        'day': [
            '15', '16', '17', '18', '19', '20', '21', '22',
        ],
	'time': [
            '00:00', '06:00', '12:00', '18:00',
        ],
	'area': [50, -120, 0, -30], # North, West, South, East
    },
    'era5_pressure_maria.grib')

c.retrieve(
    'reanalysis-era5-single-levels',
    {
     	'product_type': 'reanalysis',
        'format': 'grib',
        'variable': [
            '10m_u_component_of_wind', 
            '10m_v_component_of_wind',
            '2m_dewpoint_temperature', 
            '2m_temperature',
            'mean_sea_level_pressure', 
            'surface_pressure',
            'skin_temperature', 
            'sea_surface_temperature',
            'sea_ice_cover', 
            'snow_depth',
            'soil_temperature_level_1', 
            'soil_temperature_level_2',
            'soil_temperature_level_3', 
            'soil_temperature_level_4',
            'volumetric_soil_water_layer_1', 
            'volumetric_soil_water_layer_2',
            'volumetric_soil_water_layer_3', 
            'volumetric_soil_water_layer_4',
            'land_sea_mask',
        ],
	'year': '2017',
        'month': '09',
        'day': [
            '15', '16', '17', '18', '19', '20', '21', '22',
        ],
	'time': [
            '00:00', '06:00', '12:00', '18:00',
        ],
	'area': [50, -120, 0, -30],
    },
    'era5_surface_maria.grib')

print("downloads complete.")