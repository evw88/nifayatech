-- ============================================
-- WASTE MANAGEMENT SYSTEM DATABASE
-- Version: 1.0
-- Date: January 2026
-- ============================================

CREATE DATABASE IF NOT EXISTS ast_db;
USE ast_db;

-- ============================================
-- ROLES & PERMISSIONS SYSTEM
-- ============================================

CREATE TABLE roles (
    role_id INT PRIMARY KEY AUTO_INCREMENT,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE permissions (
    permission_id INT PRIMARY KEY AUTO_INCREMENT,
    permission_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    module VARCHAR(50) NOT NULL COMMENT 'containers, employees, routes, reports, etc.'
);

CREATE TABLE role_permissions (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(permission_id) ON DELETE CASCADE
);

-- ============================================
-- USERS SYSTEM
-- ============================================

CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    role_id INT NOT NULL,
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active',
    last_login TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(role_id),
    INDEX idx_email (email),
    INDEX idx_status (status)
);

-- ============================================
-- GEOGRAPHICAL ZONES
-- ============================================

CREATE TABLE zones (
    zone_id INT PRIMARY KEY AUTO_INCREMENT,
    zone_name VARCHAR(100) NOT NULL,
    zone_code VARCHAR(20) UNIQUE,
    city VARCHAR(100),
    district VARCHAR(100),
    population INT,
    area_km2 DECIMAL(10,2),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- CONTAINER MANAGEMENT
-- ============================================

CREATE TABLE container_types (
    type_id INT PRIMARY KEY AUTO_INCREMENT,
    type_name VARCHAR(50) NOT NULL UNIQUE COMMENT 'general, plastic, metal, glass, organic, paper',
    color_code VARCHAR(7) COMMENT 'Hex color for map markers',
    description TEXT
);

CREATE TABLE containers (
    container_id INT PRIMARY KEY AUTO_INCREMENT,
    container_code VARCHAR(50) NOT NULL UNIQUE,
    type_id INT NOT NULL,
    capacity_liters INT NOT NULL,
    current_fill_percentage DECIMAL(5,2) DEFAULT 0.00 COMMENT '0.00 to 100.00',
    current_fill_liters DECIMAL(10,2) GENERATED ALWAYS AS (capacity_liters * current_fill_percentage / 100) STORED,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    location POINT NOT NULL COMMENT 'Spatial data for MySQL GIS',
    address VARCHAR(255),
    zone_id INT,
    neighborhood VARCHAR(100),
    accessibility_notes TEXT COMMENT 'narrow street, gated community, stairs, etc.',
    status ENUM('active', 'maintenance', 'damaged', 'decommissioned') DEFAULT 'active',
    alert_threshold DECIMAL(5,2) DEFAULT 80.00 COMMENT 'Trigger collection when reached',
    installation_date DATE,
    last_emptied_at TIMESTAMP NULL,
    last_maintenance_date DATE,
    next_scheduled_collection TIMESTAMP NULL,
    sensor_id VARCHAR(100) UNIQUE COMMENT 'IoT device identifier',
    last_sensor_update TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (type_id) REFERENCES container_types(type_id),
    FOREIGN KEY (zone_id) REFERENCES zones(zone_id),
    SPATIAL INDEX idx_location (location),
    INDEX idx_fill_level (current_fill_percentage),
    INDEX idx_status (status),
    INDEX idx_zone (zone_id)
);

CREATE TABLE sensor_readings (
    reading_id INT PRIMARY KEY AUTO_INCREMENT,
    container_id INT NOT NULL,
    fill_percentage DECIMAL(5,2) NOT NULL,
    temperature DECIMAL(5,2) COMMENT 'Celsius',
    humidity DECIMAL(5,2) COMMENT 'Percentage',
    battery_level DECIMAL(5,2) COMMENT 'Sensor battery percentage',
    signal_strength INT COMMENT 'RSSI value',
    reading_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (container_id) REFERENCES containers(container_id) ON DELETE CASCADE,
    INDEX idx_container_time (container_id, reading_timestamp),
    INDEX idx_timestamp (reading_timestamp)
);

-- ============================================
-- EMPLOYEES & WORK MANAGEMENT
-- ============================================

CREATE TABLE employee_types (
    type_id INT PRIMARY KEY AUTO_INCREMENT,
    type_name VARCHAR(50) NOT NULL UNIQUE COMMENT 'driver, collector, supervisor, maintenance, admin'
);

CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL UNIQUE,
    employee_code VARCHAR(50) NOT NULL UNIQUE,
    employee_type_id INT NOT NULL,
    hire_date DATE NOT NULL,
    salary DECIMAL(10,2),
    license_number VARCHAR(50) COMMENT 'For drivers',
    license_expiry DATE,
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    status ENUM('active', 'on_leave', 'terminated') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (employee_type_id) REFERENCES employee_types(type_id),
    INDEX idx_type (employee_type_id),
    INDEX idx_status (status)
);

CREATE TABLE work_shifts (
    shift_id INT PRIMARY KEY AUTO_INCREMENT,
    shift_name VARCHAR(50) NOT NULL UNIQUE,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    description TEXT
);

CREATE TABLE work_timeline (
    timeline_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    shift_id INT,
    work_date DATE NOT NULL,
    clock_in TIMESTAMP NULL,
    clock_out TIMESTAMP NULL,
    break_duration_minutes INT DEFAULT 0,
    total_hours DECIMAL(5,2) GENERATED ALWAYS AS (
        CASE 
            WHEN clock_in IS NOT NULL AND clock_out IS NOT NULL 
            THEN TIMESTAMPDIFF(MINUTE, clock_in, clock_out) / 60.0 - (break_duration_minutes / 60.0)
            ELSE 0 
        END
    ) STORED,
    status ENUM('scheduled', 'in_progress', 'completed', 'absent', 'late') DEFAULT 'scheduled',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE,
    FOREIGN KEY (shift_id) REFERENCES work_shifts(shift_id),
    INDEX idx_employee_date (employee_id, work_date),
    INDEX idx_date (work_date)
);

-- ============================================
-- VEHICLE MANAGEMENT (FIXED)
-- ============================================

CREATE TABLE vehicles (
    vehicle_id INT PRIMARY KEY AUTO_INCREMENT,
    vehicle_code VARCHAR(50) NOT NULL UNIQUE,
    license_plate VARCHAR(20) NOT NULL UNIQUE,
    vehicle_type ENUM('truck', 'compactor', 'van', 'pickup') NOT NULL,
    brand VARCHAR(50),
    model VARCHAR(50),
    year INT,
    capacity_kg INT NOT NULL,
    fuel_type ENUM('diesel', 'petrol', 'electric', 'hybrid'),
    current_latitude DECIMAL(10,8),
    current_longitude DECIMAL(11,8),
    operational_status ENUM('available', 'in_use', 'maintenance', 'out_of_service') DEFAULT 'available',
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    odometer_km INT DEFAULT 0,
    purchase_date DATE,
    insurance_expiry DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_status (operational_status),
    INDEX idx_coordinates (current_latitude, current_longitude)
);

CREATE TABLE vehicle_maintenance (
    maintenance_id INT PRIMARY KEY AUTO_INCREMENT,
    vehicle_id INT NOT NULL,
    maintenance_date DATE NOT NULL,
    maintenance_type ENUM('routine', 'repair', 'inspection', 'emergency') NOT NULL,
    description TEXT,
    cost DECIMAL(10,2),
    technician_name VARCHAR(100),
    next_service_date DATE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE CASCADE,
    INDEX idx_vehicle_date (vehicle_id, maintenance_date)
);

CREATE TABLE vehicle_assignments (
    assignment_id INT PRIMARY KEY AUTO_INCREMENT,
    vehicle_id INT NOT NULL,
    employee_id INT NOT NULL COMMENT 'Driver',
    assignment_date DATE NOT NULL,
    start_time TIMESTAMP,
    end_time TIMESTAMP NULL,
    start_odometer INT,
    end_odometer INT,
    fuel_consumed_liters DECIMAL(8,2),
    status ENUM('assigned', 'in_progress', 'completed') DEFAULT 'assigned',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    INDEX idx_vehicle_date (vehicle_id, assignment_date),
    INDEX idx_employee (employee_id)
);

-- ============================================
-- COLLECTION ROUTES
-- ============================================

CREATE TABLE routes (
    route_id INT PRIMARY KEY AUTO_INCREMENT,
    route_name VARCHAR(100) NOT NULL,
    route_code VARCHAR(50) UNIQUE,
    zone_id INT,
    estimated_duration_minutes INT,
    total_distance_km DECIMAL(10,2),
    priority_level ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
    status ENUM('active', 'inactive', 'temporary') DEFAULT 'active',
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (zone_id) REFERENCES zones(zone_id),
    INDEX idx_zone (zone_id),
    INDEX idx_priority (priority_level)
);

CREATE TABLE route_containers (
    route_container_id INT PRIMARY KEY AUTO_INCREMENT,
    route_id INT NOT NULL,
    container_id INT NOT NULL,
    sequence_order INT NOT NULL COMMENT 'Order of collection in route',
    estimated_time_minutes INT COMMENT 'Time to reach from previous point',
    FOREIGN KEY (route_id) REFERENCES routes(route_id) ON DELETE CASCADE,
    FOREIGN KEY (container_id) REFERENCES containers(container_id) ON DELETE CASCADE,
    UNIQUE KEY unique_route_container (route_id, container_id),
    INDEX idx_route_order (route_id, sequence_order)
);

CREATE TABLE collection_schedules (
    schedule_id INT PRIMARY KEY AUTO_INCREMENT,
    route_id INT NOT NULL,
    vehicle_id INT,
    driver_id INT COMMENT 'Employee ID of driver',
    partner_id INT COMMENT 'Assistant/partner employee',
    scheduled_date DATE NOT NULL,
    scheduled_start_time TIME,
    actual_start_time TIMESTAMP NULL,
    actual_end_time TIMESTAMP NULL,
    status ENUM('scheduled', 'in_progress', 'completed', 'cancelled') DEFAULT 'scheduled',
    total_collected_kg DECIMAL(10,2),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (route_id) REFERENCES routes(route_id),
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
    FOREIGN KEY (driver_id) REFERENCES employees(employee_id),
    FOREIGN KEY (partner_id) REFERENCES employees(employee_id),
    INDEX idx_date_status (scheduled_date, status),
    INDEX idx_route (route_id)
);

CREATE TABLE shift_swap_requests (
    request_id INT PRIMARY KEY AUTO_INCREMENT,
    requester_employee_id INT NOT NULL,
    target_employee_id INT NOT NULL,
    schedule_id INT NOT NULL,
    target_schedule_id INT NOT NULL,
    status ENUM('pending', 'accepted', 'declined', 'cancelled') DEFAULT 'pending',
    message TEXT,
    responded_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (requester_employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE,
    FOREIGN KEY (target_employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE,
    FOREIGN KEY (schedule_id) REFERENCES collection_schedules(schedule_id) ON DELETE CASCADE,
    FOREIGN KEY (target_schedule_id) REFERENCES collection_schedules(schedule_id) ON DELETE CASCADE,
    INDEX idx_requester (requester_employee_id),
    INDEX idx_target (target_employee_id),
    INDEX idx_status (status),
    UNIQUE KEY unique_swap_request (requester_employee_id, target_employee_id, schedule_id, status)
);

CREATE TABLE collection_reports (
    report_id INT PRIMARY KEY AUTO_INCREMENT,
    schedule_id INT NOT NULL,
    container_id INT NOT NULL,
    collection_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fill_level_before DECIMAL(5,2),
    fill_level_after DECIMAL(5,2) DEFAULT 0.00,
    collected_weight_kg DECIMAL(10,2),
    collection_duration_minutes INT,
    issues_reported TEXT,
    photo_url VARCHAR(255) COMMENT 'Evidence photo if needed',
    latitude DECIMAL(10,8) COMMENT 'Actual collection location',
    longitude DECIMAL(11,8),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (schedule_id) REFERENCES collection_schedules(schedule_id) ON DELETE CASCADE,
    FOREIGN KEY (container_id) REFERENCES containers(container_id),
    INDEX idx_schedule (schedule_id),
    INDEX idx_container_time (container_id, collection_timestamp)
);

-- ============================================
-- RECYCLING PARTNERS & SALES
-- ============================================

CREATE TABLE material_types (
    material_id INT PRIMARY KEY AUTO_INCREMENT,
    material_name VARCHAR(50) NOT NULL UNIQUE COMMENT 'plastic, metal, paper, glass, organic',
    description TEXT,
    unit VARCHAR(20) DEFAULT 'kg',
    recyclable BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE partners (
    partner_id INT PRIMARY KEY AUTO_INCREMENT,
    partner_name VARCHAR(100) NOT NULL,
    contact_person VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT,
    partner_type ENUM('buyer', 'recycler', 'processor', 'supplier') DEFAULT 'buyer',
    status ENUM('active', 'inactive', 'blacklisted') DEFAULT 'active',
    payment_terms VARCHAR(100) COMMENT 'e.g., 30 days, immediate, etc.',
    rating DECIMAL(3,2) COMMENT '0.00 to 5.00',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_type_status (partner_type, status)
);

CREATE TABLE partner_materials (
    partner_material_id INT PRIMARY KEY AUTO_INCREMENT,
    partner_id INT NOT NULL,
    material_id INT NOT NULL,
    current_price_per_kg DECIMAL(10,2) NOT NULL,
    minimum_quantity_kg DECIMAL(10,2),
    last_price_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (partner_id) REFERENCES partners(partner_id) ON DELETE CASCADE,
    FOREIGN KEY (material_id) REFERENCES material_types(material_id),
    UNIQUE KEY unique_partner_material (partner_id, material_id)
);

CREATE TABLE material_inventory (
    inventory_id INT PRIMARY KEY AUTO_INCREMENT,
    material_id INT NOT NULL,
    quantity_kg DECIMAL(10,2) NOT NULL DEFAULT 0,
    location VARCHAR(100) COMMENT 'Storage facility/warehouse',
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    notes TEXT,
    FOREIGN KEY (material_id) REFERENCES material_types(material_id),
    INDEX idx_material (material_id)
);

CREATE TABLE sales_transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    partner_id INT NOT NULL,
    material_id INT NOT NULL,
    quantity_kg DECIMAL(10,2) NOT NULL,
    price_per_kg DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(12,2) GENERATED ALWAYS AS (quantity_kg * price_per_kg) STORED,
    transaction_date DATE NOT NULL,
    payment_status ENUM('pending', 'partial', 'paid', 'overdue') DEFAULT 'pending',
    payment_date DATE NULL,
    invoice_number VARCHAR(50) UNIQUE,
    notes TEXT,
    created_by INT COMMENT 'User ID who created transaction',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (partner_id) REFERENCES partners(partner_id),
    FOREIGN KEY (material_id) REFERENCES material_types(material_id),
    FOREIGN KEY (created_by) REFERENCES users(user_id),
    INDEX idx_partner_date (partner_id, transaction_date),
    INDEX idx_payment_status (payment_status)
);

-- ============================================
-- ALERTS & NOTIFICATIONS
-- ============================================

CREATE TABLE alerts (
    alert_id INT PRIMARY KEY AUTO_INCREMENT,
    alert_type ENUM('container_full', 'maintenance_due', 'collection_delayed', 'sensor_offline', 'low_battery', 'system') NOT NULL,
    severity ENUM('low', 'medium', 'high', 'critical') DEFAULT 'medium',
    container_id INT NULL,
    vehicle_id INT NULL,
    route_id INT NULL,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    is_resolved BOOLEAN DEFAULT FALSE,
    assigned_to INT COMMENT 'User ID assigned to handle alert',
    resolved_by INT,
    resolved_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (container_id) REFERENCES containers(container_id) ON DELETE CASCADE,
    FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE CASCADE,
    FOREIGN KEY (route_id) REFERENCES routes(route_id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_to) REFERENCES users(user_id),
    FOREIGN KEY (resolved_by) REFERENCES users(user_id),
    INDEX idx_status (is_read, is_resolved),
    INDEX idx_type_severity (alert_type, severity),
    INDEX idx_created (created_at)
);

-- ============================================
-- TRIGGERS
-- ============================================

DELIMITER //

-- Trigger to create alert when container reaches threshold
CREATE TRIGGER trg_container_alert
AFTER UPDATE ON containers
FOR EACH ROW
BEGIN
    IF NEW.current_fill_percentage >= NEW.alert_threshold 
       AND OLD.current_fill_percentage < NEW.alert_threshold 
       AND NEW.status = 'active' THEN
        INSERT INTO alerts (alert_type, severity, container_id, title, message)
        VALUES (
            'container_full',
            'high',
            NEW.container_id,
            CONCAT('Container ', NEW.container_code, ' requires collection'),
            CONCAT('Container at ', NEW.address, ' has reached ', NEW.current_fill_percentage, '% capacity')
        );
    END IF;
END//

-- Trigger to update container after sensor reading
CREATE TRIGGER trg_update_container_from_sensor
AFTER INSERT ON sensor_readings
FOR EACH ROW
BEGIN
    UPDATE containers 
    SET current_fill_percentage = NEW.fill_percentage,
        last_sensor_update = NEW.reading_timestamp
    WHERE container_id = NEW.container_id;
END//

-- Trigger to update inventory after sale
CREATE TRIGGER trg_update_inventory_after_sale
AFTER INSERT ON sales_transactions
FOR EACH ROW
BEGIN
    UPDATE material_inventory
    SET quantity_kg = quantity_kg - NEW.quantity_kg
    WHERE material_id = NEW.material_id;
END//

DELIMITER ;

-- ============================================
-- USEFUL VIEWS
-- ============================================

-- View for container status with location
CREATE VIEW v_container_status AS
SELECT 
    c.container_id,
    c.container_code,
    ct.type_name,
    c.current_fill_percentage,
    c.current_fill_liters,
    c.capacity_liters,
    c.latitude,
    c.longitude,
    c.address,
    z.zone_name,
    c.status,
    c.last_emptied_at,
    c.next_scheduled_collection,
    DATEDIFF(NOW(), c.last_emptied_at) as days_since_emptied,
    CASE 
        WHEN c.current_fill_percentage >= c.alert_threshold THEN 'urgent'
        WHEN c.current_fill_percentage >= 60 THEN 'soon'
        ELSE 'normal'
    END as collection_priority
FROM containers c
JOIN container_types ct ON c.type_id = ct.type_id
LEFT JOIN zones z ON c.zone_id = z.zone_id;

-- View for active employees with details
CREATE VIEW v_active_employees AS
SELECT 
    e.employee_id,
    e.employee_code,
    u.full_name,
    u.email,
    u.phone,
    et.type_name as employee_type,
    e.hire_date,
    TIMESTAMPDIFF(YEAR, e.hire_date, CURDATE()) as years_of_service,
    e.status
FROM employees e
JOIN users u ON e.user_id = u.user_id
JOIN employee_types et ON e.employee_type_id = et.type_id
WHERE e.status = 'active';

-- View for scheduled collections today
CREATE VIEW v_today_collections AS
SELECT 
    cs.schedule_id,
    r.route_name,
    v.license_plate,
    CONCAT(u_driver.full_name) as driver_name,
    CONCAT(u_partner.full_name) as partner_name,
    cs.scheduled_start_time,
    cs.status,
    COUNT(rc.container_id) as total_containers,
    r.estimated_duration_minutes
FROM collection_schedules cs
JOIN routes r ON cs.route_id = r.route_id
LEFT JOIN vehicles v ON cs.vehicle_id = v.vehicle_id
LEFT JOIN employees e_driver ON cs.driver_id = e_driver.employee_id
LEFT JOIN users u_driver ON e_driver.user_id = u_driver.user_id
LEFT JOIN employees e_partner ON cs.partner_id = e_partner.employee_id
LEFT JOIN users u_partner ON e_partner.user_id = u_partner.user_id
LEFT JOIN route_containers rc ON r.route_id = rc.route_id
WHERE cs.scheduled_date = CURDATE()
GROUP BY cs.schedule_id;

-- View for material inventory with values
CREATE VIEW v_inventory_value AS
SELECT 
    mi.inventory_id,
    mt.material_name,
    mi.quantity_kg,
    mi.location,
    COALESCE(AVG(pm.current_price_per_kg), 0) as avg_market_price,
    COALESCE(mi.quantity_kg * AVG(pm.current_price_per_kg), 0) as estimated_value
FROM material_inventory mi
JOIN material_types mt ON mi.material_id = mt.material_id
LEFT JOIN partner_materials pm ON mi.material_id = pm.material_id
GROUP BY mi.inventory_id;

-- ============================================
-- INITIAL DATA SETUP
-- ============================================

-- Insert default roles
INSERT INTO roles (role_name, description) VALUES
('admin', 'Full system access and management'),
('employer', 'Manages employees, routes, and operations'),
('user', 'Basic access for viewing information'),
('driver', 'Access to assigned routes and collection tasks');

-- Insert default permissions
INSERT INTO permissions (permission_name, description, module) VALUES
('view_containers', 'View container information and status', 'containers'),
('manage_containers', 'Add, edit, delete containers', 'containers'),
('view_routes', 'View collection routes', 'routes'),
('manage_routes', 'Create and modify routes', 'routes'),
('view_employees', 'View employee information', 'employees'),
('manage_employees', 'Hire, edit, terminate employees', 'employees'),
('view_reports', 'View system reports and analytics', 'reports'),
('manage_sales', 'Create and manage sales transactions', 'sales'),
('manage_partners', 'Add and manage recycling partners', 'partners'),
('view_vehicles', 'View vehicle information', 'vehicles'),
('manage_vehicles', 'Add and maintain vehicles', 'vehicles'),
('system_admin', 'Full administrative access', 'system');

-- Assign permissions to admin role
INSERT INTO role_permissions (role_id, permission_id)
SELECT 1, permission_id FROM permissions;

-- Assign permissions to employer role
INSERT INTO role_permissions (role_id, permission_id)
SELECT 2, permission_id FROM permissions 
WHERE permission_name IN ('view_containers', 'manage_containers', 'view_routes', 
    'manage_routes', 'view_employees', 'manage_employees', 'view_reports', 
    'view_vehicles', 'manage_vehicles');

-- Insert container types
INSERT INTO container_types (type_name, color_code, description) VALUES
('general', '#808080', 'General mixed waste'),
('plastic', '#FFEB3B', 'Plastic and recyclable materials'),
('metal', '#9E9E9E', 'Metal waste and cans'),
('glass', '#4CAF50', 'Glass bottles and containers'),
('organic', '#8BC34A', 'Organic and compostable waste'),
('paper', '#2196F3', 'Paper and cardboard');

-- Insert employee types
INSERT INTO employee_types (type_name) VALUES
('driver'),
('collector'),
('supervisor'),
('maintenance'),
('admin');

-- Insert work shifts
INSERT INTO work_shifts (shift_name, start_time, end_time, description) VALUES
('Morning Shift', '06:00:00', '14:00:00', 'Early morning collection'),
('Day Shift', '08:00:00', '16:00:00', 'Regular day operations'),
('Evening Shift', '14:00:00', '22:00:00', 'Evening and night collection'),
('Night Shift', '22:00:00', '06:00:00', 'Night operations for commercial areas');

-- Insert material types
INSERT INTO material_types (material_name, description, recyclable) VALUES
('plastic', 'PET, HDPE, PVC, LDPE, PP, PS plastics', TRUE),
('metal', 'Aluminum, steel, copper, brass', TRUE),
('paper', 'Cardboard, newspapers, office paper', TRUE),
('glass', 'Clear, brown, green glass', TRUE),
('organic', 'Food waste, yard waste, compostables', FALSE),
('electronics', 'E-waste, circuit boards, batteries', TRUE),
('textiles', 'Clothing, fabric waste', TRUE);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Additional indexes for common queries
CREATE INDEX idx_users_role ON users(role_id, status);
CREATE INDEX idx_containers_alert ON containers(current_fill_percentage, status);
CREATE INDEX idx_work_timeline_date_employee ON work_timeline(work_date, employee_id);
CREATE INDEX idx_sales_date ON sales_transactions(transaction_date, payment_status);
CREATE INDEX idx_sensor_readings_recent ON sensor_readings(container_id, reading_timestamp DESC);

-- ============================================
-- END OF SCHEMA
-- ============================================
