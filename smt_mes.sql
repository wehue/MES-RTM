-- ============================================================
-- SMT MES系统数据库初始化脚本
-- 包含：数据库创建、选择、全部29张表的建表语句
-- 字符集: utf8mb4  排序规则: utf8mb4_unicode_ci
-- ============================================================

-- 创建数据库
CREATE DATABASE smt_mes
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

-- 选择数据库
USE smt_mes;

-- ============================================================
-- 表名: smt_equipment_types
-- 说明: SMT设备类型字典（印刷机/SPI/高速贴片机/泛用贴片机/回流炉/AOI）
-- 模块: MES-MDM 模块1 - 设备管理
-- ============================================================
CREATE TABLE smt_equipment_types (
    -- 主键
                                     Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                                     TypeCode              VARCHAR(20)     NOT NULL                 COMMENT '设备类型编码',
                                     TypeName              VARCHAR(50)     NOT NULL                 COMMENT '设备类型名称',
                                     TypeDescription           VARCHAR(200)    NULL                     COMMENT '设备类型描述',

    -- 通用字段
                                     CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                                     CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                                     UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                                     UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                                     IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                                     LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                                     LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                                     PRIMARY KEY (Id),
                                     UNIQUE INDEX uq_equipment_type_code (TypeCode),
                                     INDEX idx_type_name (TypeName)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='SMT设备类型字典';


-- ============================================================
-- 表名: smt_lines
-- 说明: SMT产线主数据，记录产线基本信息
-- 模块: MES-MDM 模块2 - 产品和产线管理
-- 逻辑关联: 设备通过 smt_equipment.LineId 关联本表
-- ============================================================
CREATE TABLE smt_lines (
    -- 主键
                           Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                           LineCode              VARCHAR(50)     NOT NULL                 COMMENT '产线编号（业务唯一）',
                           LineName              VARCHAR(100)    NOT NULL                 COMMENT '产线名称',
                           LineDescription           VARCHAR(200)    NULL                 COMMENT '描述',
                           Workshop              VARCHAR(50)     NULL                     COMMENT '所属车间',-- 因为没有车间管理的模块，所以这里没有对车间进行单独建模

    -- 通用字段
                           CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                           CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                           UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                           UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                           IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                           LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                           LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                           PRIMARY KEY (Id),
                           UNIQUE INDEX uq_line_code (LineCode),
                           INDEX idx_line_name (LineName)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='SMT产线主数据';

-- ============================================================
-- 表名: smt_equipment
-- 说明: SMT设备档案，记录每一台物理设备的基本信息
-- 模块: MES-MDM 模块1 - 设备管理
-- 逻辑关联: EquipmentTypeId → smt_equipment_types.Id
--           LineId          → smt_lines.Id（模块2）

-- 如果不需要体现产线设备顺序，设备档案表则使用这个表
-- ============================================================
CREATE TABLE smt_equipment (
    -- 主键
                               Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                               EquipmentCode         VARCHAR(50)     NOT NULL                 COMMENT '设备编号（业务唯一）',
                               EquipmentName         VARCHAR(100)    NOT NULL                 COMMENT '设备名称',
                               EquipmentTypeId       BIGINT          NOT NULL                 COMMENT '设备类型ID（逻辑关联 smt_equipment_types.Id）',
                               Model                 VARCHAR(50)     NULL                     COMMENT '设备型号',
                               Brand                 VARCHAR(50)     NULL                     COMMENT '品牌',
                               SerialNumber          VARCHAR(100)    NULL                     COMMENT '出厂序列号',
                               ProductionDate        DATE            NULL                     COMMENT '投产日期',
                               WarrantyExpireDate    DATE            NULL                     COMMENT '保修截止日期',
                               LineId                BIGINT          NULL                     COMMENT '所属产线ID（逻辑关联 smt_lines.Id，模块2）',
                               Status                TINYINT         NOT NULL DEFAULT 1       COMMENT '设备状态: 1-运行, 2-待机, 3-故障, 4-保养, 5-离线, 6-报废',

    -- 通用字段
                               CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                               CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                               UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                               UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                               IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                               LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                               LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                               PRIMARY KEY (Id),
                               UNIQUE INDEX uq_equipment_code (EquipmentCode),
                               INDEX idx_equipment_type (EquipmentTypeId),
                               INDEX idx_line (LineId),
                               INDEX idx_status (Status),
                               INDEX idx_equipment_name (EquipmentName),
                               CONSTRAINT chk_equipment_status CHECK (Status BETWEEN 1 AND 6),
                               CONSTRAINT fk_equipment_equipment_type FOREIGN KEY (EquipmentTypeId) REFERENCES smt_equipment_types(Id),
                               CONSTRAINT fk_equipment_line FOREIGN KEY (LineId) REFERENCES smt_lines(Id)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='SMT设备档案';


-- ============================================================
-- 表名: smt_equipment_package_types
-- 说明: 设备类型与封装类型的匹配关系，定义每种设备类型可处理的封装类型
-- 模块: MES-MDM 模块1 - 设备管理
-- 逻辑关联: EquipmentTypeId → smt_equipment_types.Id
--           封装类型不独立建模，通过 PackageType 直接字符匹配
-- 用途: 生产上料时校验物料封装是否匹配设备能力，设备分配时过滤兼容设备
--
-- PackageType 字段使用方式（不进行独立建模，直接通过字符匹配，不建外键）
-- ============================================================
CREATE TABLE smt_equipment_package_types (
    -- 主键
                                            Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                                            EquipmentTypeId       BIGINT          NOT NULL                 COMMENT '设备类型ID（逻辑关联 smt_equipment_types.Id）',
                                            PackageType           VARCHAR(20)     NOT NULL                 COMMENT '封装类型（如 0201, 0402, QFP, BGA）',

    -- 通用字段
                                            CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                                            CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                                            UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                                            UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                                            IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                                            LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                                            LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                                            PRIMARY KEY (Id),-- 主键
                                            UNIQUE INDEX uq_equipment_package (EquipmentTypeId, PackageType),-- 唯一索引，确保一个设备类型下没有重复的封装类型
                                            INDEX idx_equipment_type (EquipmentTypeId),-- 设备类型索引，用于快速查询
                                            INDEX idx_package_type (PackageType),-- 封装类型索引，用于快速查询
                                            CONSTRAINT fk_equip_pkg_equipment_type FOREIGN KEY (EquipmentTypeId) REFERENCES smt_equipment_types(Id)-- 设备类型外键，关联 smt_equipment_types.Id
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='设备类型与封装类型匹配表';


-- ============================================================
-- 表名: smt_product_types
-- 说明: 产品类型字典，定义产品的分类（如手机主板、电源板等）
-- 模块: MES-MDM 模块2 - 产品和产线管理
-- 逻辑关联: 产品通过 smt_products.ProductTypeId 关联本表
-- ============================================================
CREATE TABLE smt_product_types (
    -- 主键
                                   Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                                   TypeCode              VARCHAR(20)     NOT NULL                 COMMENT '产品类型编码',
                                   TypeName              VARCHAR(50)     NOT NULL                 COMMENT '产品类型名称',

    -- 通用字段
                                   CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                                   CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                                   UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                                   UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                                   IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                                   LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                                   LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                                   PRIMARY KEY (Id),
                                   UNIQUE INDEX uq_product_type_code (TypeCode),
                                   INDEX idx_type_name (TypeName)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='产品类型字典';


-- ============================================================
-- 表名: smt_products
-- 说明: 产品主数据，记录每一种产品的详细档案和设计版本
-- 模块: MES-MDM 模块2 - 产品和产线管理
-- 逻辑关联: ProductTypeId → smt_product_types.Id
--           DefaultRouteId → smt_routes.Id（产品默认使用的工艺路线）
--           BOM 通过 smt_bom.ProductId 关联本表，BOM行项通过 smt_bom_items.BomId 关联 smt_bom
--           工艺路线通过 ProductTypeId 间接匹配
--           SPI/AOI直通率阈值直接在产品维度配置，质量管理时按产品标准判定
-- ============================================================
CREATE TABLE smt_products (
    -- 主键
                              Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                              ProductCode           VARCHAR(50)     NOT NULL                 COMMENT '产品编码（业务唯一）',
                              ProductName           VARCHAR(100)    NOT NULL                 COMMENT '产品名称',
                              Model                 VARCHAR(50)     NULL                     COMMENT '产品型号',
                              Version               VARCHAR(20)     NULL                     COMMENT '设计版本',
                              PCBDimensions         VARCHAR(50)     NULL                     COMMENT 'PCB尺寸（如 100x80mm）',
                              PCBThickness          VARCHAR(20)     NULL                     COMMENT 'PCB厚度（如 1.6mm）',
                              PanelCount            INT             NULL                     COMMENT '拼板数量',
                              ProductTypeId         BIGINT          NOT NULL                 COMMENT '产品类型ID（逻辑关联 smt_product_types.Id）',
                              SpiThreshold          DECIMAL(5,2)    NULL                     COMMENT 'SPI检测直通率阈值（如95.00），由工艺配置师设置',
                              AoiThreshold          DECIMAL(5,2)    NULL                     COMMENT 'AOI检测直通率阈值（如95.00），由工艺配置师设置',
                              DefaultRouteId        BIGINT          NULL                     COMMENT '默认工艺路线ID（逻辑关联 smt_routes.Id），产品投产时如未指定路线则使用此默认值',

    -- 通用字段
                              CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                              CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                              UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                              UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                              IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                              LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                              LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                              PRIMARY KEY (Id),
                              UNIQUE INDEX uq_product_code (ProductCode),
                              INDEX idx_product_type (ProductTypeId),
                              INDEX idx_product_name (ProductName),
                              INDEX idx_default_route (DefaultRouteId)                         COMMENT '按默认工艺路线查询产品',
                              CONSTRAINT fk_product_product_type FOREIGN KEY (ProductTypeId) REFERENCES smt_product_types(Id),
                              CONSTRAINT chk_spi_threshold CHECK (SpiThreshold BETWEEN 0 AND 100),
                              CONSTRAINT chk_aoi_threshold CHECK (AoiThreshold BETWEEN 0 AND 100)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='产品主数据';


-- ============================================================
-- 表名: smt_bom
-- 说明: BOM版本头表，管理产品BOM的版本，同一产品可有多个版本但仅一个为激活状态
-- 模块: MES-MDM 模块2 - 产品和产线管理
-- 逻辑关联: ProductId → smt_products.Id
--           BOM行项通过 smt_bom_items.BomId 关联本表
-- 约束说明: 通过虚拟生成列 ActiveProductKey 确保同一产品仅有一条 IsActive=1 的记录
--          系统做生产准备时只允许抓取 IsActive=1 的最新版本
-- ============================================================
CREATE TABLE smt_bom (
    -- 主键
                         Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                         ProductId             BIGINT          NOT NULL                 COMMENT '产品ID（逻辑关联 smt_products.Id）',
                         BomVersion            VARCHAR(20)     NOT NULL                 COMMENT 'BOM版本号（如 V1.0, V2.0）',
                         IsActive              BIT             NOT NULL DEFAULT 0       COMMENT '是否激活: 0-历史版本, 1-当前生效版本',
                         Description           VARCHAR(200)    NULL                     COMMENT '版本描述/变更说明',

    -- 约束辅助字段（非业务字段，仅用于数据库级唯一约束，确保同一产品仅有一条 IsActive=1 的记录）
                         ActiveProductKey      BIGINT          GENERATED ALWAYS AS (CASE WHEN IsActive = 1 THEN ProductId ELSE NULL END) STORED COMMENT '激活产品唯一键，配合下方 uq_bom_active 约束确保同一产品仅允许一个激活版本',

    -- 通用字段
                         CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                         CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                         UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                         UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                         IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                         LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                         LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                         PRIMARY KEY (Id),
                         UNIQUE INDEX uq_bom_version (ProductId, BomVersion),
                         UNIQUE INDEX uq_bom_active (ActiveProductKey),
                         INDEX idx_bom_product (ProductId),
                         INDEX idx_bom_active (IsActive),
                         CONSTRAINT fk_bom_product FOREIGN KEY (ProductId) REFERENCES smt_products(Id)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='BOM版本头表';


-- ============================================================
-- 表名: smt_material_types
-- 说明: 物料类型字典（电阻/电容/电感/IC/连接器/结构件）
-- 模块: MES-MDM 模块3 - 物料管理
-- ============================================================
CREATE TABLE smt_material_types (
    -- 主键
                                    Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                                    TypeCode              VARCHAR(20)     NOT NULL                 COMMENT '物料类型编码（唯一）',
                                    TypeName              VARCHAR(50)     NOT NULL                 COMMENT '物料类型名称',

    -- 通用字段
                                    CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                                    CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                                    UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                                    UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                                    IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                                    LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                                    LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                                    PRIMARY KEY (Id),
                                    UNIQUE INDEX uq_material_type_code (TypeCode),
                                    INDEX idx_type_name (TypeName)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='物料类型字典';


-- ============================================================
-- 表名: smt_materials
-- 说明: 物料主数据，记录所有元件的基本信息
-- 模块: MES-MDM 模块3 - 物料管理
-- 逻辑关联: MaterialTypeId → smt_material_types.Id
-- ============================================================
CREATE TABLE smt_materials (
    -- 主键
                               Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                               MaterialCode          VARCHAR(50)     NOT NULL                 COMMENT '元件料号（业务唯一）',
                               MaterialDesc          VARCHAR(200)    NOT NULL                 COMMENT '物料描述',
                               MaterialTypeId        BIGINT          NOT NULL                 COMMENT '物料类型ID（逻辑关联 smt_material_types.Id）',
                               PackageType           VARCHAR(20)     NULL                     COMMENT '封装类型',
                               Brand                 VARCHAR(50)     NULL                     COMMENT '品牌',
                               MinPackQty            INT             NULL                     COMMENT '最小包装量',
                               StorageCondition      VARCHAR(50)     NULL                     COMMENT '存储条件',
                               MSDLevel              VARCHAR(10)     NULL                     COMMENT 'MSD湿度敏感等级',
                               MaterialBarcode       VARCHAR(50)     NULL                     COMMENT '物料条码（业务唯一），用于扫码上料等场景快速识别物料',

    -- 通用字段
                               CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                               CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                               UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                               UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                               IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                               LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                               LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                               PRIMARY KEY (Id),
                               UNIQUE INDEX uq_material_code (MaterialCode),
                               UNIQUE INDEX uq_material_barcode (MaterialBarcode)             COMMENT '物料条码全局唯一',
                               INDEX idx_material_type (MaterialTypeId),
                               INDEX idx_material_desc (MaterialDesc),
                               CONSTRAINT fk_material_material_type FOREIGN KEY (MaterialTypeId) REFERENCES smt_material_types(Id)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='物料主数据';


-- ============================================================
-- 表名: smt_material_substitutes
-- 说明: 替代料关系表，记录物料之间的替代规则
-- 模块: MES-MDM 模块3 - 物料管理
-- 逻辑关联: MaterialId          → smt_materials.Id (主料)
--           SubstituteMaterialId → smt_materials.Id (替代料)
-- ============================================================
CREATE TABLE smt_material_substitutes (
    -- 主键
                                          Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                                          MaterialId            BIGINT          NOT NULL                 COMMENT '主料ID（逻辑关联 smt_materials.Id）',
                                          SubstituteMaterialId  BIGINT          NOT NULL                 COMMENT '替代料ID（逻辑关联 smt_materials.Id）',
                                          Direction             TINYINT         NOT NULL DEFAULT 1       COMMENT '替代方向: 1-单向, 2-双向',
                                          Priority              INT             NOT NULL DEFAULT 1       COMMENT '优先级（数字越小越优先）',

    -- 通用字段
                                          CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                                          CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                                          UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                                          UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                                          IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                                          LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                                          LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                                          PRIMARY KEY (Id),
                                          UNIQUE INDEX uq_substitute (MaterialId, SubstituteMaterialId)  COMMENT '同一主料与替代料关系唯一',
                                          INDEX idx_material (MaterialId),
                                          INDEX idx_substitute_material (SubstituteMaterialId),
                                          CONSTRAINT fk_substitute_material FOREIGN KEY (MaterialId) REFERENCES smt_materials(Id),
                                          CONSTRAINT fk_substitute_substitute_material FOREIGN KEY (SubstituteMaterialId) REFERENCES smt_materials(Id)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='替代料关系表';


-- ============================================================
-- 表名: smt_bom_items
-- 说明: BOM行项，记录每个BOM版本中的元件物料、位号和用量
-- 模块: MES-MDM 模块2 - 产品和产线管理 / 模块3 - 物料管理
-- 逻辑关联: BomId      → smt_bom.Id
--           MaterialId → smt_materials.Id
--           封装类型与设备类型有匹配关系，用于上料时的校验
--           一个BOM版本对应多条BOM行项，BOM行项通过BomId关联BOM头表
-- ============================================================
CREATE TABLE smt_bom_items (
    -- 主键
                               Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                               BomId                 BIGINT          NOT NULL                 COMMENT 'BOM版本ID（逻辑关联 smt_bom.Id）',
                               MaterialId            BIGINT          NOT NULL                 COMMENT '物料ID（逻辑关联 smt_materials.Id）',
                               ReferenceDesignator   VARCHAR(50)     NULL                     COMMENT '位号（如 R1, C3, U2）',
                               Quantity              DECIMAL(10,3)   NOT NULL                 COMMENT '单板用量',-- 默认单位为片
                               PackageType           VARCHAR(20)     NULL                     COMMENT '封装类型（如 0201, 0402, QFP）',

    -- 通用字段
                               CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                               CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                               UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                               UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                               IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                               LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                               LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                               PRIMARY KEY (Id),
                               UNIQUE INDEX uq_bom_item (BomId, MaterialId, ReferenceDesignator),
                               INDEX idx_bom (BomId),
                               INDEX idx_material (MaterialId),
                               CONSTRAINT fk_bom_item_bom FOREIGN KEY (BomId) REFERENCES smt_bom(Id),
                               CONSTRAINT fk_bom_item_material FOREIGN KEY (MaterialId) REFERENCES smt_materials(Id)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='BOM行项';


-- ============================================================
-- 表名: smt_routes
-- 说明: 工艺路线主表，记录产品类型的生产工艺流程的路线定义
-- 模块: MES-MDM 模块4 - 工艺管理
-- 逻辑关联:
--   ProductTypeId → smt_product_types.Id
--     一条路线适用一种产品类型（如"手机主板"），
--     一种产品类型可有多条路线（如标准工艺、高速工艺）
--   路线工序通过 smt_route_steps.RouteId 关联本表
--     一条路线包含多道工序，按 Sequence 顺序排列
--   工单间接关联: 工单 → 产品 → 产品类型 → 本表
-- 状态说明: Status 采用三态控制:
--   1-创建: 路线处于编辑中，不可被工单选用
--   2-发布: 路线已定版，可被工单选用
--   3-停用: 路线已废弃，不可被工单选用（历史工单仍保留关联）
-- ============================================================
CREATE TABLE smt_routes (
    -- 主键
                            Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                            RouteCode             VARCHAR(50)     NOT NULL                 COMMENT '路线编码（业务唯一，如 ROUTE-PCB-STD）',
                            RouteName             VARCHAR(100)    NOT NULL                 COMMENT '路线名称（如"手机主板标准工艺"）',
                            ProductTypeId         BIGINT          NOT NULL                 COMMENT '适用产品类型ID（逻辑关联 smt_product_types.Id，决定哪些产品可选用此路线）',
                            Description           VARCHAR(200)    NULL                     COMMENT '路线描述/备注',
                            Status                TINYINT         NOT NULL DEFAULT 1       COMMENT '状态: 1-创建(不可用), 2-发布(可用), 3-停用(不可用)',

    -- 通用字段
                            CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                            CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人（工艺工程师账号）',
                            UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                            UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                            IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                            LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                            LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注（可记录变更原因）',

    -- 约束与索引
                            PRIMARY KEY (Id),
                            UNIQUE INDEX uq_route_code (RouteCode)                        COMMENT '路线编码全局唯一',
                            INDEX idx_product_type (ProductTypeId)                        COMMENT '按适用产品类型查询',
                            INDEX idx_status (Status)                                     COMMENT '按状态筛选(创建/发布/停用)',
                            CONSTRAINT chk_route_status CHECK (Status BETWEEN 1 AND 3),
                            CONSTRAINT fk_route_product_type FOREIGN KEY (ProductTypeId) REFERENCES smt_product_types(Id)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='工艺路线主表（SMT工艺路线定义）';


-- ============================================================
-- 表名: smt_operations
-- 说明: 工序字典表，定义系统所有可用的标准工序，是工艺配置的基础数据
-- 模块: MES-MDM 模块4 - 工艺管理
-- 逻辑关联:
--   被 smt_route_steps.OperationId 引用
--     一个工序可被多条工艺路线复用
--     如"锡膏印刷"可在手机主板路线和电源板路线中都出现
--   通过 smt_route_steps.ParameterTemplateId → smt_parameter_templates
--     直接关联到工艺参数模板
--   设备类型在 smt_route_steps 中定义，同一工序在不同工艺路线中可配置不同设备类型
--   RTM进站管理: 批次进站时通过本表确定当前工序的名称
-- ============================================================
CREATE TABLE smt_operations (
    -- 主键
                                Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                                OperationCode         VARCHAR(50)     NOT NULL                 COMMENT '工序代码（业务唯一，如 PRINTER, SPI, REFLOW, AOI）',
                                OperationName         VARCHAR(100)    NOT NULL                 COMMENT '工序名称（如"锡膏印刷""SPI检测""回流焊接"）',
                                Description           VARCHAR(200)    NULL                     COMMENT '工序描述/补充说明',

    -- 通用字段
                                CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                                CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人（工艺工程师账号）',
                                UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                                UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                                IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                                LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                                LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                                PRIMARY KEY (Id),
                                UNIQUE INDEX uq_operation_code (OperationCode)                COMMENT '工序代码全局唯一',
                                INDEX idx_operation_name (OperationName)                      COMMENT '按工序名称模糊查询'
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='工序字典表（SMT工序标准定义）';

-- ============================================================
-- 表名: smt_route_steps
-- 说明: 工艺路线工序关系表，定义一条工艺路线由哪些工序按什么顺序组成
-- 模块: MES-MDM 模块4 - 工艺管理
-- 关联: RouteId             → smt_routes.Id
--       OperationId         → smt_operations.Id
--       EquipmentTypeId     → smt_equipment_types.Id（生产时设备校验）
--       ParameterTemplateId → smt_parameter_templates.Id（本表直接绑定参数模板）
--   设备类型在此处定义: EquipmentTypeId → smt_equipment_types.Id
--     同一工序在不同工艺路线中可配置不同设备类型，生产时根据此处进行设备校验
--   参数模板在此处直接绑定，无需通过产品工序参数表间接关联
-- ============================================================
CREATE TABLE smt_route_steps (
    -- 主键
                                 Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                                 RouteId               BIGINT          NOT NULL                 COMMENT '工艺路线ID（逻辑关联 smt_routes.Id）',
                                 OperationId           BIGINT          NOT NULL                 COMMENT '工序ID（逻辑关联 smt_operations.Id）',
                                 Sequence              INT             NOT NULL                 COMMENT '工序序号（10,20,30...）',
                                 EquipmentTypeId       BIGINT          NOT NULL                 COMMENT '设备类型ID（逻辑关联 smt_equipment_types.Id），生产时据此校验设备类型',
                                 ParameterTemplateId  BIGINT          NOT NULL                 COMMENT '参数模板ID（逻辑关联 smt_parameter_templates.Id），定义该工序到此路线的工艺参数',
                                 StandardTime          INT             NULL                     COMMENT '标准工时（秒），此工序在该工艺路线中的标准作业时间，用于估算批次完工时间和产线产能',

    -- 通用字段
                                 CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                                 CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                                 UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                                 UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                                 IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                                 LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                                 LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                                 PRIMARY KEY (Id),
                                 UNIQUE INDEX uq_route_operation (RouteId, OperationId),
                                 UNIQUE INDEX uq_route_sequence (RouteId, Sequence),
                                 INDEX idx_operation (OperationId),
                                 INDEX idx_equipment_type (EquipmentTypeId),
                                 INDEX idx_parameter_template (ParameterTemplateId),
                                 CONSTRAINT fk_route_step_route FOREIGN KEY (RouteId) REFERENCES smt_routes(Id),
                                 CONSTRAINT fk_route_step_operation FOREIGN KEY (OperationId) REFERENCES smt_operations(Id),
                                 CONSTRAINT fk_route_step_equipment_type FOREIGN KEY (EquipmentTypeId) REFERENCES smt_equipment_types(Id)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='工艺路线工序关系表';


-- ============================================================
-- 表名: smt_parameter_templates
-- 说明: 工艺参数模板主表，定义参数模板的基本信息
-- 模块: MES-MDM 模块4 - 工艺管理
-- 关联: EquipmentTypeId → smt_equipment_types.Id
-- ============================================================
CREATE TABLE smt_parameter_templates (
    -- 主键
                                         Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                                         TemplateCode          VARCHAR(50)     NOT NULL                 COMMENT '模板编码（业务唯一）',
                                         TemplateName          VARCHAR(100)    NOT NULL                 COMMENT '模板名称',
                                         EquipmentTypeId       BIGINT          NOT NULL                 COMMENT '适用设备类型ID（逻辑关联 smt_equipment_types.Id）',
                                         Version               VARCHAR(20)     NULL                     COMMENT '版本号',
                                         Status                TINYINT         NOT NULL DEFAULT 1       COMMENT '状态: 1-启用, 0-停用',
                                         EffectiveDate         DATE            NULL                     COMMENT '生效日期（模板从该日期起可用，NULL表示创建即生效）',
                                         ExpiryDate            DATE            NULL                     COMMENT '失效日期（模板到期自动停用，NULL表示永久有效）',

    -- 通用字段
                                         CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                                         CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                                         UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                                         UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                                         IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                                         LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                                         LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                                         PRIMARY KEY (Id),
                                         UNIQUE INDEX uq_template_code (TemplateCode),
                                         INDEX idx_equipment_type (EquipmentTypeId),
                                         INDEX idx_status (Status),
                                         CONSTRAINT fk_param_template_equipment_type FOREIGN KEY (EquipmentTypeId) REFERENCES smt_equipment_types(Id)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='工艺参数模板主表';


-- ============================================================
-- 表名: smt_parameter_items
-- 说明: 参数项明细表，存储每个参数模板的具体参数项和数值
-- 模块: MES-MDM 模块4 - 工艺管理
-- 关联: TemplateId → smt_parameter_templates.Id
-- ============================================================
CREATE TABLE smt_parameter_items (
    -- 主键
                                     Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                                     TemplateId            BIGINT          NOT NULL                 COMMENT '所属模板ID（逻辑关联 smt_parameter_templates.Id）',
                                     ParameterName         VARCHAR(100)    NOT NULL                 COMMENT '参数名称',
                                     ParameterValue        VARCHAR(100)    NULL                     COMMENT '设定值',
                                     MinLimit              VARCHAR(100)    NULL                     COMMENT '下限值',
                                     MaxLimit              VARCHAR(100)    NULL                     COMMENT '上限值',
                                     Unit                  VARCHAR(20)     NULL                     COMMENT '单位',
                                     Sequence              INT             NULL                     COMMENT '显示顺序号（用于数据库查询排序和前端页面有序展示，非必填，NULL 表示不排序）',

    -- 通用字段
                                     CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                                     CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                                     UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                                     UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                                     IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                                     LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                                     LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                                     PRIMARY KEY (Id),
                                     UNIQUE INDEX uq_template_parameter (TemplateId, ParameterName),
                                     INDEX idx_template (TemplateId),
                                     CONSTRAINT fk_param_item_template FOREIGN KEY (TemplateId) REFERENCES smt_parameter_templates(Id)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='参数项明细表';



-- ============================================================
-- 表名: smt_users
-- 说明: 系统用户表，存储所有可登录系统的用户账号及个人信息。
--       用户是操作和执行生产业务的主体，所有的进站、出站、上料、
--       维修、质量判定等操作均需关联到具体用户。
-- 模块: MES-MDM 模块5 - 用户与权限管理
-- 逻辑关联:
--   用户通过 smt_user_roles 与角色建立多对多关系，
--     进而通过角色继承权限和功能。
--   业务表中所有 OperatorId、RepairBy 等字段均逻辑关联本表 Id，
--     用于追溯操作人。
--   系统管理员可通过本表维护账号、分配部门和岗位。
-- ============================================================
CREATE TABLE smt_users (
    -- 主键
    Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
    Username              VARCHAR(50)     NOT NULL                 COMMENT '用户账号（登录名，全局唯一）',
    PasswordHash          VARCHAR(255)    NOT NULL                 COMMENT '密码哈希值，存储加密后的密码',
    FullName              VARCHAR(50)     NULL                     COMMENT '用户真实姓名，用于界面显示和操作记录展示',
    Department            VARCHAR(50)     NULL                     COMMENT '所属部门（如SMT车间、工艺部、质量部），部门未单独建模',
    Position              VARCHAR(50)     NULL                     COMMENT '岗位（如操作工、班组长、工艺工程师）',
    Contact               VARCHAR(100)    NULL                     COMMENT '联系方式（电话/邮箱等）',

    -- 通用字段
    CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人（通常为系统管理员账号）',
    UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
    UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
    IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
    LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
    LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注（如重置密码、离职禁用等）',

    -- 约束与索引
    PRIMARY KEY (Id),
    UNIQUE INDEX uq_username (Username)                           COMMENT '登录账号全局唯一，防止重复注册'
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='系统用户表（MES所有登录用户的基础信息）';


-- ============================================================
-- 表名: smt_roles
-- 说明: 角色表，定义系统中的权限角色，代表一组权限的集合。
--       通过角色可以简化权限分配，将相同权限需求的人员归为一类。
--       如"操作工"角色拥有生产执行相关的功能权限，
--       "工艺工程师"拥有工艺路线、参数模板的维护权限。
-- 模块: MES-MDM 模块5 - 用户与权限管理
-- 逻辑关联:
--   角色通过 smt_role_permissions 与权限点建立多对多关系，
--     一个角色可以包含多个权限点。
--   角色通过 smt_user_roles 分配给用户，实现用户←→权限的解耦。
--   预设角色: 操作工、班组长、工艺工程师、质量工程师、管理员。
-- ============================================================
CREATE TABLE smt_roles (
    -- 主键
    Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
    RoleCode              VARCHAR(50)     NOT NULL                 COMMENT '角色编码（英文，业务唯一，如 OPERATOR, ENGINEER, ADMIN）',
    RoleName              VARCHAR(50)     NOT NULL                 COMMENT '角色名称（中文，如"操作工""工艺工程师"）',
    Description           VARCHAR(200)    NULL                     COMMENT '角色说明，描述该角色拥有的权限范围',
		Subsystem             TINYINT         NOT NULL                 COMMENT '所属子系统: 1-MDM, 2-RTM',
    -- 通用字段
    CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人（系统管理员）',
    UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
    UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
    IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
    LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
    LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
    PRIMARY KEY (Id),
    UNIQUE INDEX uq_role_code (RoleCode)                          COMMENT '角色编码全局唯一，避免重复创建'
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='角色表（系统角色的定义）';


-- ============================================================
-- 表名: smt_functions
-- 说明: 功能模块表，定义系统中所有可被授权的功能模块。
--       粒度控制到模块级别，如"设备管理""工艺管理""用户管理"等。
--       角色通过 smt_role_functions 直接关联功能模块。
-- 模块: MES-MDM 模块5 - 用户与权限管理
-- ============================================================
CREATE TABLE smt_functions (
    -- 主键
    Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
    FunctionCode          VARCHAR(100)    NOT NULL                 COMMENT '功能编码（英文，全局唯一，如 equipment, route, user）',
    FunctionName          VARCHAR(100)    NOT NULL                 COMMENT '功能名称（中文，用于界面显示，如"设备管理""工艺管理"）',
    Description           VARCHAR(200)    NULL                     COMMENT '功能描述',

    -- 通用字段
    CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
    UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
    UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
    IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
    LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
    LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
    PRIMARY KEY (Id),
    UNIQUE INDEX uq_function_code (FunctionCode)                  COMMENT '功能编码全局唯一'
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='功能模块表（系统可授权的功能模块定义）';


-- ============================================================
-- 表名: smt_user_roles
-- 说明: 用户-角色关联表，实现用户与角色的多对多关系。
--       一个用户可以同时拥有多个角色（如既是操作工又是班组长），
--       一个角色可以分配给多个用户。
--       系统登录后通过本表获取当前用户的角色列表，再进一步获取权限。
--       为了后续扩展，这里是多对多关系，但在开发中可以简化成一对多关系（多个用户有同一个角色）。
-- 模块: MES-MDM 模块5 - 用户与权限管理
-- 逻辑关联:
--   UserId → smt_users.Id  (用户)
--   RoleId → smt_roles.Id  (角色)
--   删除用户或角色时，应先清理本表对应记录以保持一致性。
-- ============================================================
CREATE TABLE smt_user_roles (
    -- 主键
    Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
    UserId                BIGINT          NOT NULL                 COMMENT '用户ID（逻辑关联 smt_users.Id）',
    RoleId                BIGINT          NOT NULL                 COMMENT '角色ID（逻辑关联 smt_roles.Id）',

    -- 通用字段
    CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人（分配权限的操作人，通常为系统管理员）',
    UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
    UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
    IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除（解除关联）',
    LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
    LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
    PRIMARY KEY (Id),
    UNIQUE INDEX uq_user_role (UserId, RoleId)                    COMMENT '同一用户对同一角色只能关联一次',
    INDEX idx_user (UserId)                                       COMMENT '按用户查询其拥有的角色',
    INDEX idx_role (RoleId)                                       COMMENT '按角色查询其下用户',
    CONSTRAINT fk_user_role_user FOREIGN KEY (UserId) REFERENCES smt_users(Id),
    CONSTRAINT fk_user_role_role FOREIGN KEY (RoleId) REFERENCES smt_roles(Id)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='用户-角色关联表（用户与角色的多对多关系）';

-- ============================================================
-- 表名: smt_role_functions
-- 说明: 角色-功能关联表，实现角色与功能模块的多对多关系。
--       一个角色可以拥有多个功能模块的权限，
--       一个功能模块也可以分配给多个角色。
--       系统通过本表确定每个角色能访问哪些功能模块。
-- 模块: MES-MDM 模块5 - 用户与权限管理
-- 逻辑关联:
--   RoleId     → smt_roles.Id
--   FunctionId → smt_functions.Id
-- ============================================================
CREATE TABLE smt_role_functions (
    -- 主键
    Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
    RoleId                BIGINT          NOT NULL                 COMMENT '角色ID（逻辑关联 smt_roles.Id）',
    FunctionId            BIGINT          NOT NULL                 COMMENT '功能模块ID（逻辑关联 smt_functions.Id）',

    -- 通用字段
    CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
    UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
    UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
    IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
    LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
    LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
    PRIMARY KEY (Id),
    UNIQUE INDEX uq_role_function (RoleId, FunctionId)            COMMENT '同一角色对同一功能模块只关联一次',
    INDEX idx_role (RoleId)                                       COMMENT '按角色查询其功能模块',
    INDEX idx_function (FunctionId)                               COMMENT '按功能模块查询被哪些角色拥有',
    CONSTRAINT fk_role_function_role FOREIGN KEY (RoleId) REFERENCES smt_roles(Id),
    CONSTRAINT fk_role_function_function FOREIGN KEY (FunctionId) REFERENCES smt_functions(Id)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci
COMMENT='角色-功能关联表（角色与功能模块的多对多关系）';




-- ============================================================
-- 表名: smt_work_orders
-- 说明: 工单表，记录生产指令
-- 模块: MES-RTM 模块1 - 生产调度
-- 逻辑关联: ProductId → smt_products.Id
--           RouteId   → smt_routes.Id

-- 工单状态流转说明: 1-草稿(工单创建还未确定), 2-已释放(工单确定下达), 3-生产中(第一批次进入生产), 4-已暂停(所有批次均暂停), 5-已完成(所有批次均完成), 6-已关闭(生产完结归档)
-- ============================================================
CREATE TABLE smt_work_orders (
    -- 主键
                                 Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                                 WorkOrderCode         VARCHAR(50)     NOT NULL                 COMMENT '工单号（日期+流水号，业务唯一）',
                                 ProductId             BIGINT          NOT NULL                 COMMENT '产品ID（逻辑关联 smt_products.Id）',
                                 RouteId               BIGINT          NOT NULL                 COMMENT '工艺路线ID（逻辑关联 smt_routes.Id）',
                                 PlannedQuantity       INT             NOT NULL                 COMMENT '计划生产数量',
                                 DueDate               DATETIME        NULL                     COMMENT '交货期限',
                                 Status                TINYINT         NOT NULL DEFAULT 1       COMMENT '工单状态: 1-草稿, 2-已释放, 3-生产中, 4-已暂停, 5-已完成, 6-已关闭',

    -- 通用字段
                                 CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                                 CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                                 UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                                 UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                                 IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                                 LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                                 LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                                 PRIMARY KEY (Id),
                                 UNIQUE INDEX uq_work_order_code (WorkOrderCode),
                                 INDEX idx_product (ProductId),
                                 INDEX idx_route (RouteId),
                                 INDEX idx_status (Status),
                                 CONSTRAINT fk_work_order_product FOREIGN KEY (ProductId) REFERENCES smt_products(Id),
                                 CONSTRAINT fk_work_order_route FOREIGN KEY (RouteId) REFERENCES smt_routes(Id)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='工单表';


-- ============================================================
-- 表名: smt_lots
-- 说明: 批次表，记录工单拆分后的生产单元
--       批次状态流转: 1-待生产(批次创建) → 2-生产中(第一道工序进站) → 3-暂停 → 4-维修中 → 5-已锁定 → 6-已完成(最后一道工序出站)
--       当前所在工序通过 smt_lot_operation_status 表查询（Status=2-已进站 的行即为当前工序）
-- 模块: MES-RTM 模块1 - 生产调度
-- 逻辑关联: WorkOrderId         → smt_work_orders.Id
--           LineId              → smt_lines.Id
-- ============================================================
CREATE TABLE smt_lots (
    -- 主键
                          Id                      BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                          LotCode                 VARCHAR(50)     NOT NULL                 COMMENT '批次号（业务唯一）',
                          WorkOrderId             BIGINT          NOT NULL                 COMMENT '所属工单ID（逻辑关联 smt_work_orders.Id）',
                          LineId                  BIGINT          NOT NULL                 COMMENT '所在产线ID（逻辑关联 smt_lines.Id）',
                          PlannedQuantity         INT             NOT NULL                 COMMENT '本批次计划生产数量',
                          CompletedQuantity       INT             NOT NULL DEFAULT 0       COMMENT '已完成数量',
                          Status                  TINYINT         NOT NULL DEFAULT 1       COMMENT '批次状态: 1-待生产, 2-生产中, 3-暂停, 4-维修中, 5-已锁定, 6-已完成',
                          EstimatedCompletionTime DATETIME        NULL                     COMMENT '预计完成时间',
                          StartTime               DATETIME        NULL                     COMMENT '上线时间（进入第一道工序）',
                          EndTime                 DATETIME        NULL                     COMMENT '下线时间（完成最后一道工序）',

    -- 通用字段
                          CreatedAt               DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                          CreatedBy               VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                          UpdatedAt               DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                          UpdatedBy               VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                          IsDeleted               BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                          LastOperationType       TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                          LastOperationRemark     VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                          PRIMARY KEY (Id),
                          UNIQUE INDEX uq_lot_code (LotCode),
                          INDEX idx_work_order (WorkOrderId),
                          INDEX idx_line (LineId),
                          INDEX idx_status (Status),
                          CONSTRAINT fk_lot_work_order FOREIGN KEY (WorkOrderId) REFERENCES smt_work_orders(Id),
                          CONSTRAINT fk_lot_line FOREIGN KEY (LineId) REFERENCES smt_lines(Id)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='批次表';


-- ============================================================
-- 表名: smt_lot_operation_status
-- 说明: 批次工序状态表（当前快照），记录每个批次每道工序的实时状态
--       每道工序一条记录，状态不断更新，批次跑完后全部工序状态完整留存
--       批次投产时只创建第一道工序行（初始状态=待进站），后续工序在上一工序出站时动态创建
--       工序状态流转: 1-待进站(上一工序出站后自动进入) → 2-已进站(操作工进站) → 3-已出站(操作工出站)
--                   异常时: 4-暂停(缺料/设备故障) / 5-锁定(SPI/AOI不达标) / 6-跳过(工艺路线允许跳过时)
-- 模块: MES-RTM 模块1 - 生产调度 / 模块2 - 生产管理
-- 逻辑关联: LotId        → smt_lots.Id
--           RouteStepId  → smt_route_steps.Id
-- 与已有表的区别:
--   smt_station_in_records  / smt_station_out_records → 历史日志（每次进出站 INSERT），回答"发生过什么"
--   smt_lot_operation_status                         → 当前快照（进站/出站时 UPDATE），回答"现在每道工序什么状态"
-- ============================================================
CREATE TABLE smt_lot_operation_status (
    -- 主键
                                        Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                                        LotId                 BIGINT          NOT NULL                 COMMENT '批次ID（逻辑关联 smt_lots.Id）',
                                        RouteStepId           BIGINT          NOT NULL                 COMMENT '工序步骤ID（逻辑关联 smt_route_steps.Id）',
                                        Status                TINYINT         NOT NULL DEFAULT 1       COMMENT '工序状态: 1-待进站, 2-已进站, 3-已出站, 4-暂停, 5-锁定, 6-跳过',
                                        StationInTime         DATETIME        NULL                     COMMENT '进站时间',
                                        StationInQuantity     INT             NULL                     COMMENT '进站数量',
                                        StationOutTime        DATETIME        NULL                     COMMENT '出站时间',
                                        FinishedQuantity      INT             NULL                     COMMENT '完工数量',
                                        DefectQuantity        INT             NULL                     COMMENT '不良数量',

    -- 通用字段
                                        CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                                        CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                                        UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                                        UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                                        IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                                        LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                                        LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                                        PRIMARY KEY (Id),
                                        UNIQUE INDEX uq_lot_route_step (LotId, RouteStepId),
                                        INDEX idx_lot (LotId),
                                        INDEX idx_route_step (RouteStepId),
                                        INDEX idx_status (Status),
                                        CONSTRAINT fk_lot_op_status_lot FOREIGN KEY (LotId) REFERENCES smt_lots(Id),
                                        CONSTRAINT fk_lot_op_status_route_step FOREIGN KEY (RouteStepId) REFERENCES smt_route_steps(Id),
                                        CONSTRAINT chk_op_status CHECK (Status BETWEEN 1 AND 6)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='批次工序状态表';


-- ============================================================
-- 表名: smt_station_in_records
-- 说明: 进站记录表，记录每个批次在每道工序的每次进站事件（允许多轮次进站）
--       同一批次在同一道工序可多次进站（如维修后重新进站），通过 Round 字段区分轮次
-- 模块: MES-RTM 模块2 - 生产管理
-- 逻辑关联: LotId              → smt_lots.Id
--           RouteStepId        → smt_route_steps.Id
--           EquipmentId        → smt_equipment.Id
--           OperatorId         → smt_users.Id
--   参数模板通过业务链路推导: LotId→工单→ProductId → smt_products.DefaultRouteId → smt_route_steps
-- ============================================================
CREATE TABLE smt_station_in_records (
    -- 主键
                                        Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                                        LotId                 BIGINT          NOT NULL                 COMMENT '批次ID（逻辑关联 smt_lots.Id）',
                                        RouteStepId           BIGINT          NOT NULL                 COMMENT '工序步骤ID（逻辑关联 smt_route_steps.Id）',
                                        Round                 INT             NOT NULL DEFAULT 1       COMMENT '进站轮次（同一批次在同一道工序的进站序号，从1开始递增；第1次进站=1，维修后重新进站=2...）',
                                        EquipmentId           BIGINT          NULL                     COMMENT '所选设备ID（逻辑关联 smt_equipment.Id）',
                                        OperatorId            BIGINT          NOT NULL                 COMMENT '进站操作员ID（逻辑关联 smt_users.Id）',
                                        StationInTime         DATETIME        NULL                     COMMENT '进站时间',
                                        StationInQuantity     INT             NULL                     COMMENT '进站数量',
                                        Status                TINYINT         NOT NULL DEFAULT 1       COMMENT '进站状态: 1-校验通过, 2-校验失败',
                                        VerifyRemark          VARCHAR(200)    NULL                     COMMENT '校验失败原因',

    -- 通用字段
                                        CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                                        CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                                        UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                                        UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                                        IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                                        LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                                        LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                                        PRIMARY KEY (Id),
                                        UNIQUE INDEX uq_lot_step_round (LotId, RouteStepId, Round),
                                        INDEX idx_lot (LotId),
                                        INDEX idx_route_step (RouteStepId),
                                        INDEX idx_equipment (EquipmentId),
                                        INDEX idx_operator (OperatorId),
                                        INDEX idx_status (Status),
                                        CONSTRAINT chk_station_in_status CHECK (Status BETWEEN 1 AND 2),
                                        CONSTRAINT fk_station_in_lot FOREIGN KEY (LotId) REFERENCES smt_lots(Id),
                                        CONSTRAINT fk_station_in_route_step FOREIGN KEY (RouteStepId) REFERENCES smt_route_steps(Id),
                                        CONSTRAINT fk_station_in_equipment FOREIGN KEY (EquipmentId) REFERENCES smt_equipment(Id),
                                        CONSTRAINT fk_station_in_operator FOREIGN KEY (OperatorId) REFERENCES smt_users(Id)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='进站记录表';


-- ============================================================
-- 表名: smt_station_out_records
-- 说明: 出站记录表，记录每个批次在每道工序的每次出站事件（允许多轮次出站）
--       与进站记录表通过 (LotId, RouteStepId, Round) 精确配对
-- 模块: MES-RTM 模块2 - 生产管理
-- 逻辑关联: LotId        → smt_lots.Id (冗余)
--           RouteStepId  → smt_route_steps.Id (冗余)
--           OperatorId   → smt_users.Id
--   检测结果记录: SPI/AOI工序出站时填写直通率，与 smt_products.SpiThreshold/AoiThreshold 比对判定
-- ============================================================
CREATE TABLE smt_station_out_records (
    -- 主键
                                         Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                                         LotId                 BIGINT          NOT NULL                 COMMENT '批次ID（逻辑关联 smt_lots.Id）',
                                         RouteStepId           BIGINT          NOT NULL                 COMMENT '工序步骤ID（冗余，逻辑关联 smt_route_steps.Id）',
                                         Round                 INT             NOT NULL DEFAULT 1       COMMENT '出站轮次（与进站记录表的 Round 对应，标识属于第几轮进出站；默认第1轮）',
                                         OperatorId            BIGINT          NOT NULL                 COMMENT '出站操作员ID（逻辑关联 smt_users.Id）',
                                         StationOutTime        DATETIME        NULL                     COMMENT '出站时间',
                                         FinishedQuantity      INT             NULL                     COMMENT '完工数量',
                                         DefectQuantity        INT             NULL                     COMMENT '不良数量',
                                         IsNormal              BIT             NOT NULL DEFAULT 1       COMMENT '出站类型: 1-正常出站, 0-异常出站',
                                         DisposalType          TINYINT         NULL                     COMMENT '不良处置: 1-维修, 2-报废, 3-强制出站（IsNormal=0时必填）',
                                         DisposalRemark        VARCHAR(200)    NULL                     COMMENT '处置原因（强制出站时必填）',
                                         SpiPassRate           DECIMAL(5,2)    NULL                     COMMENT 'SPI检测直通率百分比（SPI工序出站时填写，与产品SPI阈值比对）',
                                         AoiPassRate           DECIMAL(5,2)    NULL                     COMMENT 'AOI检测直通率百分比（AOI工序出站时填写，与产品AOI阈值比对）',

    -- 通用字段
                                         CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                                         CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                                         UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                                         UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                                         IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                                         LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                                         LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                                         PRIMARY KEY (Id),
                                         UNIQUE INDEX uq_lot_step_round (LotId, RouteStepId, Round),
                                         INDEX idx_lot (LotId),
                                         INDEX idx_route_step (RouteStepId),
                                         INDEX idx_operator (OperatorId),
                                         CONSTRAINT fk_station_out_lot FOREIGN KEY (LotId) REFERENCES smt_lots(Id),
                                         CONSTRAINT fk_station_out_route_step FOREIGN KEY (RouteStepId) REFERENCES smt_route_steps(Id),
                                         CONSTRAINT fk_station_out_operator FOREIGN KEY (OperatorId) REFERENCES smt_users(Id),
                                         CONSTRAINT chk_spi_pass_rate CHECK (SpiPassRate BETWEEN 0 AND 100),
                                         CONSTRAINT chk_aoi_pass_rate CHECK (AoiPassRate BETWEEN 0 AND 100)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='出站记录表';


-- ============================================================
-- 表名: smt_loading_records
-- 说明: 上料记录表，记录操作员在何时给哪台设备上了什么料多少数量
--       上料必须在批次和工序已明确后进行，不允许提前上料
-- 模块: MES-RTM 模块2 - 生产管理
-- 逻辑关联: LotId        → smt_lots.Id
--           RouteStepId  → smt_route_steps.Id
--           EquipmentId  → smt_equipment.Id
--           MaterialId   → smt_materials.Id
--           OperatorId   → smt_users.Id
-- ============================================================
CREATE TABLE smt_loading_records (
    -- 主键
                                     Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                                     LotId                 BIGINT          NOT NULL                 COMMENT '批次ID（逻辑关联 smt_lots.Id）',
                                     RouteStepId           BIGINT          NOT NULL                 COMMENT '工序步骤ID（逻辑关联 smt_route_steps.Id）',
                                     EquipmentId           BIGINT          NOT NULL                 COMMENT '设备ID（逻辑关联 smt_equipment.Id）',
                                     MaterialId            BIGINT          NOT NULL                 COMMENT '物料ID（逻辑关联 smt_materials.Id）',
                                     OperatorId            BIGINT          NOT NULL                 COMMENT '上料操作员ID（逻辑关联 smt_users.Id）',
                                     LoadingTime           DATETIME        NULL                     COMMENT '上料时间',
                                     ActualQuantity        INT             NULL                     COMMENT '实际上料数量',
                                     VerifyStatus          TINYINT         NOT NULL DEFAULT 0       COMMENT '校验结果: 0-未校验, 1-校验通过, 2-校验失败',
                                     VerifyRemark          VARCHAR(200)    NULL                     COMMENT '校验失败原因',

    -- 通用字段
                                     CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                                     CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                                     UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                                     UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                                     IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                                     LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                                     LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                                     PRIMARY KEY (Id),
                                     INDEX idx_lot (LotId),
                                     INDEX idx_route_step (RouteStepId),
                                     INDEX idx_equipment (EquipmentId),
                                     INDEX idx_material (MaterialId),
                                     INDEX idx_operator (OperatorId),
                                     CONSTRAINT fk_loading_lot FOREIGN KEY (LotId) REFERENCES smt_lots(Id),
                                     CONSTRAINT fk_loading_route_step FOREIGN KEY (RouteStepId) REFERENCES smt_route_steps(Id),
                                     CONSTRAINT fk_loading_equipment FOREIGN KEY (EquipmentId) REFERENCES smt_equipment(Id),
                                     CONSTRAINT fk_loading_material FOREIGN KEY (MaterialId) REFERENCES smt_materials(Id),
                                     CONSTRAINT fk_loading_operator FOREIGN KEY (OperatorId) REFERENCES smt_users(Id)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='上料记录表';


-- ============================================================
-- 表名: smt_unloading_records
-- 说明: 下料记录表，记录一次完整下料操作的详细信息
--       与上料记录表一一对应，通过 UnloadQuantity 记录卸下数量，通过 RemainQuantity 记录卸后残留
--       下料必须在批次和工序已明确后进行，通过 LoadingRecordId 关联上料记录
-- 模块: MES-RTM 模块2 - 生产管理
-- 逻辑关联: LoadingRecordId → smt_loading_records.Id（关联对应的上料记录）
--           LotId           → smt_lots.Id
--           RouteStepId     → smt_route_steps.Id
--           EquipmentId     → smt_equipment.Id
--           MaterialId      → smt_materials.Id
--           OperatorId      → smt_users.Id
-- ============================================================
CREATE TABLE smt_unloading_records (
    -- 主键
                                     Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                                     LoadingRecordId       BIGINT          NOT NULL                 COMMENT '关联上料记录ID（逻辑关联 smt_loading_records.Id），明确下料对应哪次上料',
                                     LotId                 BIGINT          NOT NULL                 COMMENT '批次ID（逻辑关联 smt_lots.Id）',
                                     RouteStepId           BIGINT          NOT NULL                 COMMENT '工序步骤ID（逻辑关联 smt_route_steps.Id）',
                                     EquipmentId           BIGINT          NOT NULL                 COMMENT '设备ID（逻辑关联 smt_equipment.Id）',
                                     MaterialId            BIGINT          NOT NULL                 COMMENT '物料ID（逻辑关联 smt_materials.Id）',
                                     UnloadingTime         DATETIME        NULL                     COMMENT '下料时间',
                                     OperatorId            BIGINT          NOT NULL                 COMMENT '下料操作员ID（逻辑关联 smt_users.Id）',
                                     Reason                TINYINT         NULL                     COMMENT '下料原因: 1-批次完工换线, 2-物料耗尽, 3-品质异常, 4-其他',
                                     UnloadQuantity        INT             NULL                     COMMENT '下料数量（支持部分下料，卸下数量可小于剩余数量）',
                                     InitialQuantity       INT             NULL                     COMMENT '初始上料数量（从关联的上料记录获取）',
                                     ActualUsedQuantity    INT             NULL                     COMMENT '实际使用数量（本次生产中实际消耗的物料数量）',
                                     RemainQuantity        INT             NULL                     COMMENT '剩余数量（下料时物料的实际剩余量）',
                                     WastageQuantity       INT             NULL                     COMMENT '损耗数量（因抛料/不良等原因造成的损耗）',
                                     Remark                VARCHAR(200)    NULL                     COMMENT '下料备注',

    -- 通用字段
                                     CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                                     CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                                     UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                                     UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                                     IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                                     LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                                     LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                                     PRIMARY KEY (Id),
                                     INDEX idx_loading_record (LoadingRecordId),
                                     INDEX idx_lot (LotId),
                                     INDEX idx_route_step (RouteStepId),
                                     INDEX idx_equipment (EquipmentId),
                                     INDEX idx_material (MaterialId),
                                     INDEX idx_operator (OperatorId),
                                     CONSTRAINT fk_unloading_loading_record FOREIGN KEY (LoadingRecordId) REFERENCES smt_loading_records(Id),
                                     CONSTRAINT fk_unloading_lot FOREIGN KEY (LotId) REFERENCES smt_lots(Id),
                                     CONSTRAINT fk_unloading_route_step FOREIGN KEY (RouteStepId) REFERENCES smt_route_steps(Id),
                                     CONSTRAINT fk_unloading_equipment FOREIGN KEY (EquipmentId) REFERENCES smt_equipment(Id),
                                     CONSTRAINT fk_unloading_material FOREIGN KEY (MaterialId) REFERENCES smt_materials(Id),
                                     CONSTRAINT fk_unloading_operator FOREIGN KEY (OperatorId) REFERENCES smt_users(Id),
                                     CONSTRAINT chk_unloading_quantity CHECK (RemainQuantity IS NULL OR RemainQuantity >= 0)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='下料记录表';


-- ============================================================
-- 表名: smt_repair_records
-- 说明: 维修记录表，记录不良品的维修过程和结果
--       维修发生在某个批次的某道工序出站后（异常出站→送修），维修完成后批次回到同一工序重新进站
--       维修记录不关心进出站的轮次（Round），仅通过 LotId + RouteStepId 定位需要回到哪个批次的哪道工序
-- 模块: MES-RTM 模块2 - 生产管理
-- 逻辑关联: LotId        → smt_lots.Id
--           RouteStepId  → smt_route_steps.Id（维修发生在哪道工序，维修完成后回该工序重新进站）
--           RepairBy     → smt_users.Id
-- ============================================================
CREATE TABLE smt_repair_records (
    -- 主键
                                    Id                    BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '主键',

    -- 业务字段
                                    LotId                 BIGINT          NOT NULL                 COMMENT '批次ID（逻辑关联 smt_lots.Id）',
                                    RouteStepId           BIGINT          NOT NULL                 COMMENT '工序步骤ID（逻辑关联 smt_route_steps.Id；维修发生在该工序，维修完成后批次回到此工序重新进站）',
                                    Status                TINYINT         NOT NULL DEFAULT 0       COMMENT '维修状态: 0-待维修, 1-维修中, 2-已完成',
                                    RepairQuantity        INT             NOT NULL                 COMMENT '送修数量',
                                    RepairedQuantity      INT             NULL                     COMMENT '已修复数量',
                                    ScrapQuantity         INT             NULL                     COMMENT '维修中报废数量',
                                    RepairDescription     VARCHAR(200)    NULL                     COMMENT '故障原因及维修措施',
                                    RepairResult          TINYINT         NULL                     COMMENT '维修结果: 1-已修复, 2-报废',
                                    RepairBy              BIGINT          NULL                     COMMENT '维修操作员ID（逻辑关联 smt_users.Id）',
                                    RepairStartTime       DATETIME        NULL                     COMMENT '维修开始时间',
                                    RepairEndTime         DATETIME        NULL                     COMMENT '维修结束时间',

    -- 通用字段
                                    CreatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
                                    CreatedBy             VARCHAR(50)     NOT NULL                 COMMENT '创建人',
                                    UpdatedAt             DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3) COMMENT '最后修改时间',
                                    UpdatedBy             VARCHAR(50)     NOT NULL                 COMMENT '最后修改人',
                                    IsDeleted             BIT             NOT NULL DEFAULT 0       COMMENT '软删除: 0-正常, 1-已删除',
                                    LastOperationType     TINYINT         NOT NULL DEFAULT 1       COMMENT '最后操作: 1-新增, 2-修改, 3-逻辑删除',
                                    LastOperationRemark   VARCHAR(200)    NULL                     COMMENT '最后操作备注',

    -- 约束与索引
                                    PRIMARY KEY (Id),
                                    INDEX idx_lot (LotId),
                                    INDEX idx_route_step (RouteStepId),
                                    INDEX idx_status (Status),
                                    INDEX idx_repair_by (RepairBy),
                                    CONSTRAINT fk_repair_lot FOREIGN KEY (LotId) REFERENCES smt_lots(Id),
                                    CONSTRAINT fk_repair_route_step FOREIGN KEY (RouteStepId) REFERENCES smt_route_steps(Id),
                                    CONSTRAINT fk_repair_operator FOREIGN KEY (RepairBy) REFERENCES smt_users(Id)
)
    ENGINE=InnoDB
    DEFAULT CHARSET=utf8mb4
    COLLATE=utf8mb4_unicode_ci
    COMMENT='维修记录表';