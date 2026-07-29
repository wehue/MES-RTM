import { reactive } from 'vue'

const NOW = '2026-05-20 14:30'
const SYSTEM_USER_ID = 1

function auditFields(createdAt = '2026-05-20 08:00', remark = '') {
  return {
    CreatedAt: createdAt,
    CreatedBy: SYSTEM_USER_ID,
    UpdatedAt: createdAt,
    UpdatedBy: SYSTEM_USER_ID,
    IsDeleted: 0,
    LastOperationType: 'INIT',
    LastOperationRemark: remark,
  }
}

export const WORK_ORDER_STATUS_CODE = {
  draft: 1,
  released: 2,
  running: 3,
  paused: 4,
  completed: 5,
  closed: 6,
}

export const BATCH_STATUS_CODE = {
  pending: 1,
  running: 2,
  paused: 3,
  repair: 4,
  locked: 5,
  completed: 6,
}

export const PROCESS_STATUS_CODE = {
  wait_in: 1,
  checked_in: 2,
  checked_out: 3,
  paused: 4,
  locked: 5,
  skipped: 6,
}

export const DISPOSAL_TYPE_CODE = {
  repair: 1,
  scrap: 2,
  force: 3,
}

export const VERIFY_STATUS_CODE = {
  pending: 0,
  passed: 1,
  failed: 2,
}

export const REPAIR_STATUS_CODE = {
  pending: 0,
  repairing: 1,
  completed: 2,
}

export const WORK_ORDER_STATUS_KEY = {
  1: 'draft',
  2: 'released',
  3: 'running',
  4: 'paused',
  5: 'completed',
  6: 'closed',
}

export const BATCH_STATUS_KEY = {
  1: 'pending',
  2: 'running',
  3: 'paused',
  4: 'repair',
  5: 'locked',
  6: 'completed',
}

export const PROCESS_STATUS_KEY = {
  1: 'wait_in',
  2: 'checked_in',
  3: 'checked_out',
  4: 'paused',
  5: 'locked',
  6: 'skipped',
}

export const DEVICE_STATUS_KEY = {
  1: 'running',
  2: 'standby',
  3: 'fault',
  4: 'maintenance',
  5: 'offline',
  6: 'scrapped',
}

function getStatusCode(map, status) {
  return typeof status === 'number' ? status : map[status]
}

export const users = reactive([
  { Id: 1, Username: 'admin', PasswordHash: '-', FullName: '系统管理员', Department: '信息部', Position: '工厂管理层', Contact: 'admin@factory.local', ...auditFields() },
  { Id: 2, Username: 'pm01', PasswordHash: '-', FullName: '王主管', Department: '生产部', Position: '生产主管', Contact: 'pm01@factory.local', ...auditFields() },
  { Id: 3, Username: 'op01', PasswordHash: '-', FullName: '张工', Department: '生产一车间', Position: '操作工', Contact: 'op01@factory.local', ...auditFields() },
  { Id: 4, Username: 'qe01', PasswordHash: '-', FullName: '质量工程师', Department: '质量部', Position: '质量工程师', Contact: 'qe01@factory.local', ...auditFields() },
])

export const roles = reactive([
  { Id: 1, RoleCode: 'RTM_ADMIN', RoleName: 'RTM管理员', Description: 'MES-RTM 实时制造执行子系统管理员，拥有 RTM 端全部功能权限', ...auditFields() },
  { Id: 2, RoleCode: 'PRODUCTION_SUPERVISOR', RoleName: '生产主管', Description: '负责工单、批次计划与调度', ...auditFields() },
  { Id: 3, RoleCode: 'LEADER', RoleName: '班组长', Description: '负责执行协调、进站、上料、出站与异常跟进', ...auditFields() },
  { Id: 4, RoleCode: 'OPERATOR', RoleName: '操作工', Description: '负责上料、进站、出站与追溯查看', ...auditFields() },
  { Id: 5, RoleCode: 'QUALITY_ENGINEER', RoleName: '质量工程师', Description: '负责质量异常和维修处理', ...auditFields() },
])

export const functions = reactive([
  { Id: 1, FunctionCode: 'dashboard', FunctionName: '生产驾驶舱', Subsystem: 'MES-RTM', Description: '首页总览', ...auditFields() },
  { Id: 2, FunctionCode: 'work_order', FunctionName: '工单管理', Subsystem: 'MES-RTM', Description: '工单创建与释放', ...auditFields() },
  { Id: 3, FunctionCode: 'batch', FunctionName: '批次管理', Subsystem: 'MES-RTM', Description: '批次拆分与投产', ...auditFields() },
  { Id: 4, FunctionCode: 'loading', FunctionName: '上料管理', Subsystem: 'MES-RTM', Description: 'BOM 齐套校验和上料记录', ...auditFields() },
  { Id: 5, FunctionCode: 'unloading', FunctionName: '下料管理', Subsystem: 'MES-RTM', Description: '工站已上料物料的下料纠正', ...auditFields() },
  { Id: 6, FunctionCode: 'check_in', FunctionName: '进站操作', Subsystem: 'MES-RTM', Description: '批次进站', ...auditFields() },
  { Id: 7, FunctionCode: 'check_out', FunctionName: '出站操作', Subsystem: 'MES-RTM', Description: '批次出站', ...auditFields() },
  { Id: 8, FunctionCode: 'repair', FunctionName: '维修管理', Subsystem: 'MES-RTM', Description: '维修处理', ...auditFields() },
])

export const equipmentTypes = reactive([
  { Id: 1, EquipmentTypeCode: 'PRT', EquipmentTypeName: '印刷机', Description: '锡膏印刷', ...auditFields() },
  { Id: 2, EquipmentTypeCode: 'SPI', EquipmentTypeName: 'SPI 检测仪', Description: '锡膏检测', ...auditFields() },
  { Id: 3, EquipmentTypeCode: 'MNT', EquipmentTypeName: '贴片机', Description: '贴装', ...auditFields() },
  { Id: 4, EquipmentTypeCode: 'RFL', EquipmentTypeName: '回流炉', Description: '回流焊接', ...auditFields() },
  { Id: 5, EquipmentTypeCode: 'AOI', EquipmentTypeName: 'AOI 检测仪', Description: '外观检测', ...auditFields() },
])

// 封装类型字典（对应 smt_package_types）
export const packageTypes = reactive([
  { Id: 1, PackageCode: '0402', PackageName: '0402', Category: 'Chip', SizeLength: 1.0, SizeWidth: 0.5, SizeHeight: 0.3, ...auditFields() },
  { Id: 2, PackageCode: '0603', PackageName: '0603', Category: 'Chip', SizeLength: 1.6, SizeWidth: 0.8, SizeHeight: 0.4, ...auditFields() },
  { Id: 3, PackageCode: '0805', PackageName: '0805', Category: 'Chip', SizeLength: 2.0, SizeWidth: 1.25, SizeHeight: 0.5, ...auditFields() },
  { Id: 4, PackageCode: 'QFN32', PackageName: 'QFN32', Category: 'IC', SizeLength: 5.0, SizeWidth: 5.0, SizeHeight: 0.9, ...auditFields() },
  { Id: 5, PackageCode: 'BGA256', PackageName: 'BGA256', Category: 'IC', SizeLength: 17.0, SizeWidth: 17.0, SizeHeight: 1.2, ...auditFields() },
])

// 设备类型支持的封装类型（对应 smt_equipment_package_types）
// 贴片机支持所有贴片封装；其他设备类型不需要上 BOM 物料
export const equipmentPackageTypes = reactive([
  // 贴片机（Id=3）支持所有封装
  { Id: 1, EquipmentTypeId: 3, PackageTypeId: 1, ...auditFields() }, // 0402
  { Id: 2, EquipmentTypeId: 3, PackageTypeId: 2, ...auditFields() }, // 0603
  { Id: 3, EquipmentTypeId: 3, PackageTypeId: 3, ...auditFields() }, // 0805
  { Id: 4, EquipmentTypeId: 3, PackageTypeId: 4, ...auditFields() }, // QFN32
  { Id: 5, EquipmentTypeId: 3, PackageTypeId: 5, ...auditFields() }, // BGA256
])

export const lines = reactive([
  {
    Id: 1,
    LineCode: 'SMT-A1',
    LineName: 'SMT-A1 标准线',
    LineDescription: '工业控制主板 SMT 标准产线',
    Workshop: '一车间',
    ...auditFields(),
  },
])

export const lineOptions = lines.map((line) => line.LineCode)

export const equipment = reactive([
  { Id: 1, EquipmentCode: 'PRT-A1-01', EquipmentName: 'A1 印刷机', EquipmentTypeId: 1, Model: 'DEK-Horizon', Brand: 'DEK', SerialNumber: 'PRT202605001', ProductionDate: '2025-01-10', WarrantyExpireDate: '2028-01-09', LineId: 1, Status: 1, ...auditFields() },
  { Id: 2, EquipmentCode: 'SPI-A1-01', EquipmentName: 'A1 SPI', EquipmentTypeId: 2, Model: 'SPI-880', Brand: 'KohYoung', SerialNumber: 'SPI202605001', ProductionDate: '2025-01-12', WarrantyExpireDate: '2028-01-11', LineId: 1, Status: 1, ...auditFields() },
  { Id: 3, EquipmentCode: 'MNT-A1-01', EquipmentName: 'A1 贴片机', EquipmentTypeId: 3, Model: 'NPM-W2', Brand: 'Panasonic', SerialNumber: 'MNT202605001', ProductionDate: '2025-01-15', WarrantyExpireDate: '2028-01-14', LineId: 1, Status: 2, ...auditFields() },
  { Id: 4, EquipmentCode: 'RFL-A1-01', EquipmentName: 'A1 回流炉', EquipmentTypeId: 4, Model: 'HELLER-1809', Brand: 'Heller', SerialNumber: 'RFL202605001', ProductionDate: '2025-01-20', WarrantyExpireDate: '2028-01-19', LineId: 1, Status: 1, ...auditFields() },
  { Id: 5, EquipmentCode: 'AOI-A1-01', EquipmentName: 'A1 AOI', EquipmentTypeId: 5, Model: 'AOI-900', Brand: 'TRI', SerialNumber: 'AOI202605001', ProductionDate: '2025-01-22', WarrantyExpireDate: '2028-01-21', LineId: 1, Status: 1, ...auditFields() },
])

export const devices = equipment

export const equipmentRuntimeState = reactive({
  'PRT-A1-01': { CurrentLotCode: 'B20260512001-01', RunDuration: '5h 12m', Oee: 88, DailyOutput: 1120, ThrowRate: '-', FaultDescription: '-' },
  'SPI-A1-01': { CurrentLotCode: 'B20260512001-01', RunDuration: '4h 50m', Oee: 86, DailyOutput: 1116, ThrowRate: '-', FaultDescription: '-' },
  'MNT-A1-01': { CurrentLotCode: '-', RunDuration: '-', Oee: 82, DailyOutput: 1100, ThrowRate: '0.18%', FaultDescription: '-' },
  'RFL-A1-01': { CurrentLotCode: 'B20260512001-01', RunDuration: '3h 40m', Oee: 84, DailyOutput: 1088, ThrowRate: '-', FaultDescription: '-' },
  'AOI-A1-01': { CurrentLotCode: 'B20260512001-01', RunDuration: '2h 10m', Oee: 87, DailyOutput: 528, ThrowRate: '-', FaultDescription: '-' },
})

export const productTypes = reactive([
  { Id: 1, ProductTypeCode: 'PCBA', ProductTypeName: 'PCBA 板卡', Description: 'SMT PCBA 产品', ...auditFields() },
])

export const products = reactive([
  {
    Id: 1,
    ProductCode: 'PCBA-RTM-100',
    ProductName: '工业控制主板',
    Model: 'PCBA-RTM-100',
    Version: 'V1.0',
    PCBDimensions: '120mm x 80mm',
    PCBThickness: 1.6,
    PanelCount: 1,
    ProductTypeId: 1,
    SpiThreshold: 97,
    AoiThreshold: 96,
    DefaultRouteId: 1,
    ...auditFields(),
  },
])

export const routes = reactive([
  {
    Id: 1,
    RouteCode: 'ROUTE-SMT-STD',
    RouteName: '标准 SMT 工艺路线',
    ProductTypeId: 1,
    Description: '印刷-SPI-贴片-回流焊接-AOI 标准流程',
    Status: 2,
    ...auditFields(),
  },
])

export const processRoutes = routes

export const operations = reactive([
  { Id: 1, OperationCode: 'PRINT', OperationName: '印刷', Description: '锡膏印刷', ...auditFields() },
  { Id: 2, OperationCode: 'SPI', OperationName: 'SPI 检测', Description: '锡膏检测', ...auditFields() },
  { Id: 3, OperationCode: 'MOUNT', OperationName: '贴片', Description: '元件贴装', ...auditFields() },
  { Id: 4, OperationCode: 'REFLOW', OperationName: '回流焊接', Description: '回流焊接', ...auditFields() },
  { Id: 5, OperationCode: 'AOI', OperationName: 'AOI 检测', Description: 'AOI 外观检测', ...auditFields() },
])

// 工站：产线中的物理工位，与工序、设备均为一对一关系
// 每条产线包含多个工序，每个工序对应一个物理工站，工站绑定一台设备实例
export const stations = reactive([
  { Id: 1, StationCode: 'ST-A1-01', StationName: 'A1 印刷工站', LineId: 1, OperationId: 1, EquipmentId: 1, Description: 'A1 线印刷工位', Status: 1, ...auditFields() },
  { Id: 2, StationCode: 'ST-A1-02', StationName: 'A1 SPI 工站', LineId: 1, OperationId: 2, EquipmentId: 2, Description: 'A1 线 SPI 检测工位', Status: 1, ...auditFields() },
  { Id: 3, StationCode: 'ST-A1-03', StationName: 'A1 贴片工站', LineId: 1, OperationId: 3, EquipmentId: 3, Description: 'A1 线贴片工位', Status: 1, ...auditFields() },
  { Id: 4, StationCode: 'ST-A1-04', StationName: 'A1 回流焊工站', LineId: 1, OperationId: 4, EquipmentId: 4, Description: 'A1 线回流焊接工位', Status: 1, ...auditFields() },
  { Id: 5, StationCode: 'ST-A1-05', StationName: 'A1 AOI 工站', LineId: 1, OperationId: 5, EquipmentId: 5, Description: 'A1 线 AOI 检测工位', Status: 1, ...auditFields() },
])

export const routeSteps = reactive([
  { Id: 101, RouteId: 1, OperationId: 1, StationId: 1, Sequence: 1, EquipmentTypeId: 1, ParameterTemplateId: null, StandardTime: 480, ...auditFields() },
  { Id: 102, RouteId: 1, OperationId: 2, StationId: 2, Sequence: 2, EquipmentTypeId: 2, ParameterTemplateId: null, StandardTime: 300, ...auditFields() },
  { Id: 103, RouteId: 1, OperationId: 3, StationId: 3, Sequence: 3, EquipmentTypeId: 3, ParameterTemplateId: null, StandardTime: 1440, ...auditFields() },
  { Id: 104, RouteId: 1, OperationId: 4, StationId: 4, Sequence: 4, EquipmentTypeId: 4, ParameterTemplateId: null, StandardTime: 1080, ...auditFields() },
  { Id: 105, RouteId: 1, OperationId: 5, StationId: 5, Sequence: 5, EquipmentTypeId: 5, ParameterTemplateId: null, StandardTime: 420, ...auditFields() },
])

export const boms = reactive([
  {
    Id: 1,
    ProductId: 1,
    BomVersion: 'V1.0',
    IsActive: 1,
    Description: '工业控制主板标准 BOM',
    ActiveProductKey: 'PCBA-RTM-100:V1.0',
    ...auditFields(),
  },
])

export const materialTypes = reactive([
  { Id: 1, MaterialTypeCode: 'RES', MaterialTypeName: '电阻', Description: '贴片电阻', ...auditFields() },
  { Id: 2, MaterialTypeCode: 'CAP', MaterialTypeName: '电容', Description: '贴片电容', ...auditFields() },
  { Id: 3, MaterialTypeCode: 'IC', MaterialTypeName: 'IC', Description: '集成电路', ...auditFields() },
  { Id: 4, MaterialTypeCode: 'LED', MaterialTypeName: 'LED', Description: '发光二极管', ...auditFields() },
])

export const materials = reactive([
  { Id: 1, MaterialCode: 'R0603-10K', MaterialDesc: '0603 10K 1% 电阻', MaterialTypeId: 1, PackageType: '0603', Brand: 'Yageo', MinPackQty: 3000, StorageCondition: '常温防潮', MSDLevel: '1', MaterialBarcode: 'R0603-10K#LOT20260520-01', ...auditFields() },
  { Id: 2, MaterialCode: 'C0402-10uF', MaterialDesc: '0402 10uF 16V 电容', MaterialTypeId: 2, PackageType: '0402', Brand: 'Murata', MinPackQty: 2000, StorageCondition: '常温防潮', MSDLevel: '1', MaterialBarcode: 'C0402-10uF#LOT20260520-01', ...auditFields() },
  { Id: 3, MaterialCode: 'C0402-10uF-B', MaterialDesc: '0402 10uF 16V 电容替代料', MaterialTypeId: 2, PackageType: '0402', Brand: 'Samsung', MinPackQty: 2000, StorageCondition: '常温防潮', MSDLevel: '1', MaterialBarcode: 'C0402-10uF-B#LOT20260520-01', ...auditFields() },
  { Id: 4, MaterialCode: 'U-QFN32-MCU', MaterialDesc: 'QFN32 MCU', MaterialTypeId: 3, PackageType: 'QFN32', Brand: 'ST', MinPackQty: 600, StorageCondition: 'MSD 管控', MSDLevel: '3', MaterialBarcode: 'U-QFN32-MCU#LOT20260520-01', ...auditFields() },
  { Id: 5, MaterialCode: 'LED0603-G', MaterialDesc: '0603 Green LED', MaterialTypeId: 4, PackageType: '0603', Brand: 'Everlight', MinPackQty: 1200, StorageCondition: '常温防潮', MSDLevel: '1', MaterialBarcode: 'LED0603-G#LOT20260520-01', ...auditFields() },
])

export const materialSubstitutes = reactive([
  { Id: 1, MaterialId: 2, SubstituteMaterialId: 3, Direction: 1, Priority: 1, ...auditFields() },
])

// 物料批次表（对应 smt_material_lots）
// 一个物料批次只能属于一个物料，同一物料可以有多个批次
export const materialLots = reactive([
  {
    Id: 1,
    MaterialCode: 'R0603-10K',
    BatchNo: 'LOT20260520-01',
    Supplier: 'Yageo',
    SupplierBatchNo: 'YG-2026-0501',
    Quantity: 3000,
    UsedQuantity: 1200,
    ProductionDate: '2026-04-15',
    ExpiryDate: '2027-04-15',
    MslLevel: 1,
    InboundDate: '2026-05-20 09:00',
    Status: '在库',
    Barcode: 'R0603-10K#LOT20260520-01',
    ...auditFields('2026-05-20 09:00', '物料入库'),
  },
  {
    Id: 2,
    MaterialCode: 'R0603-10K',
    BatchNo: 'LOT20260610-02',
    Supplier: 'Vishay',
    SupplierBatchNo: 'VS-2026-0602',
    Quantity: 2000,
    UsedQuantity: 0,
    ProductionDate: '2026-06-01',
    ExpiryDate: '2027-06-01',
    MslLevel: 1,
    InboundDate: '2026-06-10 10:30',
    Status: '在库',
    Barcode: 'R0603-10K#LOT20260610-02',
    ...auditFields('2026-06-10 10:30', '物料入库'),
  },
  {
    Id: 3,
    MaterialCode: 'C0402-10uF',
    BatchNo: 'LOT20260520-01',
    Supplier: 'Murata',
    SupplierBatchNo: 'MR-2026-0501',
    Quantity: 2000,
    UsedQuantity: 500,
    ProductionDate: '2026-04-20',
    ExpiryDate: '2027-04-20',
    MslLevel: 1,
    InboundDate: '2026-05-20 09:15',
    Status: '在库',
    Barcode: 'C0402-10uF#LOT20260520-01',
    ...auditFields('2026-05-20 09:15', '物料入库'),
  },
  {
    Id: 4,
    MaterialCode: 'U-QFN32-MCU',
    BatchNo: 'LOT20260520-01',
    Supplier: 'ST',
    SupplierBatchNo: 'ST-2026-0501',
    Quantity: 600,
    UsedQuantity: 100,
    ProductionDate: '2026-03-10',
    ExpiryDate: '2026-09-10',
    MslLevel: 3,
    InboundDate: '2026-05-20 09:30',
    Status: '在库',
    Barcode: 'U-QFN32-MCU#LOT20260520-01',
    ...auditFields('2026-05-20 09:30', '物料入库'),
  },
  {
    Id: 5,
    MaterialCode: 'LED0603-G',
    BatchNo: 'LOT20260520-01',
    Supplier: 'Everlight',
    SupplierBatchNo: 'EL-2026-0501',
    Quantity: 1200,
    UsedQuantity: 0,
    ProductionDate: '2026-05-01',
    ExpiryDate: '2027-05-01',
    MslLevel: 1,
    InboundDate: '2026-05-20 09:45',
    Status: '已冻结',
    Barcode: 'LED0603-G#LOT20260520-01',
    ...auditFields('2026-05-20 09:45', '物料入库'),
  },
])

export const bomItems = reactive([
  { Id: 1, BomId: 1, MaterialId: 1, ReferenceDesignator: 'R1,R2,R3', Quantity: 3, PackageType: '0603', ...auditFields() },
  { Id: 2, BomId: 1, MaterialId: 2, ReferenceDesignator: 'C1,C4', Quantity: 2, PackageType: '0402', ...auditFields() },
  { Id: 3, BomId: 1, MaterialId: 4, ReferenceDesignator: 'U1', Quantity: 1, PackageType: 'QFN32', ...auditFields() },
  { Id: 4, BomId: 1, MaterialId: 5, ReferenceDesignator: 'D1,D2', Quantity: 2, PackageType: '0603', ...auditFields() },
])

export const workOrders = reactive([
  {
    Id: 1,
    WorkOrderCode: 'WO20260512001',
    ProductId: 1,
    RouteId: 1,
    PlannedQuantity: 1800,
    DueDate: '2026-05-20 23:59',
    Status: WORK_ORDER_STATUS_CODE.running,
    ...auditFields('2026-05-20 08:00', '工单已释放并进入生产'),
  },
])

export const batches = reactive([
  {
    Id: 1,
    LotCode: 'B20260512005-01',
    WorkOrderId: 1,
    LineId: 1,
    PlannedQuantity: 600,
    CompletedQuantity: 0,
    Status: BATCH_STATUS_CODE.pending,
    EstimatedCompletionTime: '2026-05-20 18:00',
    StartTime: null,
    EndTime: null,
    ...auditFields('2026-05-20 14:20', '批次创建'),
  },
  {
    Id: 2,
    LotCode: 'B20260512001-01',
    WorkOrderId: 1,
    LineId: 1,
    PlannedQuantity: 600,
    CompletedQuantity: 520,
    Status: BATCH_STATUS_CODE.running,
    EstimatedCompletionTime: '2026-05-20 16:20',
    StartTime: '2026-05-20 08:42',
    EndTime: null,
    ...auditFields('2026-05-20 08:20', '批次生产中'),
  },
  {
    Id: 3,
    LotCode: 'B20260512001-02',
    WorkOrderId: 1,
    LineId: 1,
    PlannedQuantity: 600,
    CompletedQuantity: 600,
    Status: BATCH_STATUS_CODE.completed,
    EstimatedCompletionTime: '2026-05-20 12:10',
    StartTime: '2026-05-20 06:20',
    EndTime: '2026-05-20 12:10',
    ...auditFields('2026-05-20 06:00', '批次完成'),
  },
])

export const lotOperationStatus = reactive([
  {
    Id: 1,
    LotId: 2,
    RouteStepId: 105,
    Status: PROCESS_STATUS_CODE.checked_in,
    StationInTime: '2026-05-20 13:10',
    StationInQuantity: 528,
    StationOutTime: null,
    FinishedQuantity: 520,
    DefectQuantity: 7,
    ...auditFields('2026-05-20 13:10', 'AOI 已进站'),
  },
  {
    Id: 2,
    LotId: 3,
    RouteStepId: 105,
    Status: PROCESS_STATUS_CODE.checked_out,
    StationInTime: '2026-05-20 11:30',
    StationInQuantity: 600,
    StationOutTime: '2026-05-20 12:10',
    FinishedQuantity: 600,
    DefectQuantity: 0,
    ...auditFields('2026-05-20 11:30', 'AOI 已出站'),
  },
])

export const stationInRecords = reactive([
  {
    Id: 1,
    LotId: 2,
    RouteStepId: 105,
    Round: 1,
    EquipmentId: 5,
    OperatorId: 3,
    StationInTime: '2026-05-20 13:10',
    StationInQuantity: 528,
    Status: 1,
    VerifyRemark: '',
    ...auditFields('2026-05-20 13:10', 'AOI 进站'),
  },
])

export const stationOutRecords = reactive([])

export const loadingRecords = reactive([
  { Id: 1, LotId: 1, StationId: 1, RouteStepId: 101, EquipmentId: 1, MaterialId: 1, MaterialLotId: 1, OperatorId: 3, LoadingTime: '2026-05-20 14:00', ActualQuantity: 3000, VerifyStatus: 1, VerifyRemark: '', ...auditFields('2026-05-20 14:00', '上料通过') },
  { Id: 2, LotId: 1, StationId: 1, RouteStepId: 101, EquipmentId: 1, MaterialId: 2, MaterialLotId: 3, OperatorId: 3, LoadingTime: '2026-05-20 14:05', ActualQuantity: 1200, VerifyStatus: 1, VerifyRemark: '', ...auditFields('2026-05-20 14:05', '部分上料') },
  { Id: 3, LotId: 1, StationId: 1, RouteStepId: 101, EquipmentId: 1, MaterialId: 4, MaterialLotId: 4, OperatorId: 3, LoadingTime: '2026-05-20 14:08', ActualQuantity: 600, VerifyStatus: 1, VerifyRemark: '', ...auditFields('2026-05-20 14:08', '上料通过') },
  { Id: 4, LotId: 2, StationId: 1, RouteStepId: 101, EquipmentId: 1, MaterialId: 1, MaterialLotId: 1, OperatorId: 3, LoadingTime: '2026-05-20 08:30', ActualQuantity: 3000, VerifyStatus: 1, VerifyRemark: '', ...auditFields('2026-05-20 08:30', '上料通过') },
  { Id: 5, LotId: 2, StationId: 1, RouteStepId: 101, EquipmentId: 1, MaterialId: 2, MaterialLotId: 3, OperatorId: 3, LoadingTime: '2026-05-20 08:32', ActualQuantity: 2000, VerifyStatus: 1, VerifyRemark: '', ...auditFields('2026-05-20 08:32', '上料通过') },
  { Id: 6, LotId: 2, StationId: 1, RouteStepId: 101, EquipmentId: 1, MaterialId: 4, MaterialLotId: 4, OperatorId: 3, LoadingTime: '2026-05-20 08:35', ActualQuantity: 600, VerifyStatus: 1, VerifyRemark: '', ...auditFields('2026-05-20 08:35', '上料通过') },
  { Id: 7, LotId: 2, StationId: 1, RouteStepId: 101, EquipmentId: 1, MaterialId: 5, MaterialLotId: 5, OperatorId: 3, LoadingTime: '2026-05-20 08:38', ActualQuantity: 1200, VerifyStatus: 1, VerifyRemark: '', ...auditFields('2026-05-20 08:38', '上料通过') },
])

export const unloadingRecords = reactive([])
export const repairTasks = reactive([])
export const repairRecords = repairTasks

export const batchExecutionState = reactive({
  'B20260512005-01': { PendingQuantity: 0, CurrentInQuantity: 0, CurrentInTime: null, CurrentEquipmentId: null, CurrentOperatorId: null },
  'B20260512001-01': { PendingQuantity: 0, CurrentInQuantity: 528, CurrentInTime: '2026-05-20 13:10', CurrentEquipmentId: 5, CurrentOperatorId: 3 },
  'B20260512001-02': { PendingQuantity: 0, CurrentInQuantity: 0, CurrentInTime: null, CurrentEquipmentId: null, CurrentOperatorId: null },
})

export const batchTraceState = reactive({
  'B20260512005-01': [
    { Id: 'B20260512005-01-1', EventTime: '2026-05-20 14:20', EventType: 'status', RouteStepId: null, Message: '批次已创建，等待投产生成首道工序' },
  ],
  'B20260512001-01': [
    { Id: 'B20260512001-01-1', EventTime: '2026-05-20 13:10', EventType: 'checkin', RouteStepId: 105, Quantity: 528, EquipmentId: 5, OperatorId: 3, Message: 'AOI 检测已进站' },
  ],
  'B20260512001-02': [
    { Id: 'B20260512001-02-1', EventTime: '2026-05-20 12:10', EventType: 'status', RouteStepId: 105, Quantity: 600, Message: '批次全部工序完成' },
  ],
})

export const batchLoadingRequestState = reactive({})

export const alerts = reactive([
  { Id: 1, Level: 'warning', AlertType: '流程提醒', Title: 'B20260512005-01 投产后将在进站时校验 BOM 齐套', TargetUrl: '/production/batch', AlertTime: '14:20' },
])

export const messages = reactive([
  { Id: 1, Category: '生产通知', Title: '批次待投产', Content: 'B20260512005-01 已创建，投产后生成首道工序待进站。', MessageTime: '2026-05-20 14:20', IsUnread: true, LinkUrl: '/production/batch' },
])

export const qualityTrend = [
  { hour: '08:00', spi: 98.2, aoi: 97.5, batchYield: 98.8 },
  { hour: '10:00', spi: 97.9, aoi: 96.8, batchYield: 98.1 },
  { hour: '12:00', spi: 97.1, aoi: 96.9, batchYield: 97.8 },
  { hour: '14:00', spi: 98.0, aoi: 97.6, batchYield: 98.5 },
]

export const defectDistribution = [
  { name: '偏移', value: 4 },
  { name: '少锡', value: 3 },
]

export function percent(done, total) {
  if (!total) return 0
  return Math.round((done / total) * 100)
}

export function nowText() {
  return NOW
}

export function findProduct(productId) {
  return products.find((item) => item.Id === productId) || null
}

export function findProductByCode(productCode) {
  return products.find((item) => item.ProductCode === productCode || item.Model === productCode) || null
}

export function findWorkOrder(workOrderId) {
  return workOrders.find((item) => item.Id === workOrderId || item.WorkOrderCode === workOrderId) || null
}

export function findBatch(lotId) {
  return batches.find((item) => item.Id === lotId || item.LotCode === lotId) || null
}

export function findLine(lineId) {
  return lines.find((item) => item.Id === lineId || item.LineCode === lineId) || null
}

export function findEquipment(equipmentId) {
  return equipment.find((item) => item.Id === equipmentId || item.EquipmentCode === equipmentId) || null
}

export function findEquipmentType(equipmentTypeId) {
  return equipmentTypes.find((item) => item.Id === equipmentTypeId) || null
}

export function findUser(userId) {
  return users.find((item) => item.Id === userId || item.FullName === userId || item.Username === userId) || null
}

export function getUserOptionLabel(user) {
  if (!user) return '-'
  return `${user.FullName} / ${user.Position} / ${user.Department}`
}

export function getUserDisplayName(userId) {
  const user = findUser(userId)
  return user ? `${user.FullName} / ${user.Position}` : '-'
}

export function findRoute(routeId) {
  return routes.find((item) => item.Id === routeId || item.RouteCode === routeId) || null
}

export function findOperation(operationId) {
  return operations.find((item) => item.Id === operationId) || null
}

export function findRouteStep(routeStepId) {
  return routeSteps.find((item) => item.Id === routeStepId) || null
}

export function findStation(stationId) {
  return stations.find((item) => item.Id === stationId) || null
}

// 按工站 ID 查询绑定的设备信息（工站与设备一对一）
export function getStationEquipment(stationId) {
  const station = findStation(stationId)
  if (!station) return null
  return equipment.find((item) => item.Id === station.EquipmentId) || null
}

// 按产线 ID 和工序 ID 查询工站
export function findStationByLineOperation(lineId, operationId) {
  return stations.find((item) => item.LineId === lineId && item.OperationId === operationId) || null
}

export function routeById(routeId) {
  return findRoute(routeId) || routes[0]
}

export function routeOptionsByProduct(productKey) {
  const product = typeof productKey === 'number' ? findProduct(productKey) : findProductByCode(productKey)
  if (!product) return []
  return routes.filter((route) => route.ProductTypeId === product.ProductTypeId && route.Status === 2)
}

export function getRouteStepRows(routeId) {
  return routeSteps
    .filter((step) => step.RouteId === routeId)
    .sort((a, b) => a.Sequence - b.Sequence)
    .map((step) => {
      const operation = findOperation(step.OperationId)
      const equipmentType = equipmentTypes.find((item) => item.Id === step.EquipmentTypeId)
      const station = findStation(step.StationId)
      const stationEquipment = station ? getStationEquipment(station.Id) : null
      return {
        ...step,
        OperationCode: operation?.OperationCode || '',
        OperationName: operation?.OperationName || '-',
        EquipmentTypeName: equipmentType?.EquipmentTypeName || '-',
        StationCode: station?.StationCode || '',
        StationName: station?.StationName || '-',
        EquipmentCode: stationEquipment?.EquipmentCode || '',
        EquipmentName: stationEquipment?.EquipmentName || '-',
        StandardTimeText: `${Math.round((step.StandardTime || 0) / 60)} 分钟`,
      }
    })
}

export function getRouteFirstStep(routeId) {
  return getRouteStepRows(routeId)[0] || null
}

export function getWorkOrderProduct(order) {
  return order ? findProduct(order.ProductId) : null
}

export function getWorkOrderRoute(order) {
  return order ? findRoute(order.RouteId) : null
}

export function getWorkOrderLots(order) {
  if (!order) return []
  return batches.filter((batch) => batch.WorkOrderId === order.Id)
}

export function getWorkOrderCompletedQuantity(order) {
  return getWorkOrderLots(order).reduce((sum, batch) => sum + (batch.CompletedQuantity || 0), 0)
}

export function getWorkOrderReleasedBatchCount(order) {
  return getWorkOrderLots(order).length
}

export function getWorkOrderCompletedBatchCount(order) {
  return getWorkOrderLots(order).filter((batch) => batch.Status === BATCH_STATUS_CODE.completed).length
}

export function getBatchWorkOrder(batch) {
  return batch ? findWorkOrder(batch.WorkOrderId) : null
}

export function getBatchProduct(batch) {
  const order = getBatchWorkOrder(batch)
  return getWorkOrderProduct(order)
}

export function getBatchLine(batch) {
  return batch ? findLine(batch.LineId) : null
}

export function getBatchDefectQuantity(batch) {
  if (!batch) return 0
  return lotOperationStatus
    .filter((record) => record.LotId === batch.Id)
    .reduce((sum, record) => sum + (record.DefectQuantity || 0), 0)
}

export function getBatchScrapQuantity(batch) {
  if (!batch) return 0
  const repairScrapQuantity = repairTasks
    .filter((record) => record.LotId === batch.Id)
    .reduce((sum, record) => sum + (record.ScrapQuantity || 0), 0)
  const directScrapQuantity = stationOutRecords
    .filter((record) => record.LotId === batch.Id)
    .reduce((sum, record) => sum + (record.ScrapQuantity || 0), 0)
  return repairScrapQuantity + directScrapQuantity
}

export function getCurrentProcess(batchOrCode) {
  const batch = typeof batchOrCode === 'object' ? batchOrCode : findBatch(batchOrCode)
  if (!batch) return null
  const records = lotOperationStatus.filter((record) => record.LotId === batch.Id)
  return records[records.length - 1] || null
}

export function getCurrentProcessStatus(batchCode) {
  const process = getCurrentProcess(batchCode)
  return process?.Status || ''
}

export function getCurrentOperationName(batchOrCode) {
  const process = getCurrentProcess(batchOrCode)
  if (!process) return '-'
  const routeStep = findRouteStep(process.RouteStepId)
  return findOperation(routeStep?.OperationId)?.OperationName || '-'
}

// 按 mock 批次获取当前工序对应的工站（与工序、设备均为一对一关系）
export function getBatchCurrentStation(batchOrCode) {
  const process = getCurrentProcess(batchOrCode)
  if (!process) return null
  const routeStep = findRouteStep(process.RouteStepId)
  if (!routeStep?.StationId) return null
  return findStation(routeStep.StationId)
}

export function getBatchPendingQty(batchCode) {
  const state = batchExecutionState[batchCode]
  return state?.PendingQuantity || 0
}

export function getBatchCurrentInQty(batchCode) {
  const state = batchExecutionState[batchCode]
  return state?.CurrentInQuantity || 0
}

export function getEquipmentTypeName(equipmentTypeId) {
  return equipmentTypes.find((item) => item.Id === equipmentTypeId)?.EquipmentTypeName || '-'
}

export function getEquipmentRuntime(equipmentItem) {
  return equipmentRuntimeState[equipmentItem?.EquipmentCode] || {
    CurrentLotCode: '-',
    RunDuration: '-',
    Oee: 0,
    DailyOutput: 0,
    ThrowRate: '-',
    FaultDescription: '-',
  }
}

export function getLineDashboard(line) {
  const lineBatches = batches.filter((batch) => batch.LineId === line.Id && batch.Status !== BATCH_STATUS_CODE.completed)
  const currentBatch = lineBatches[0] || batches.find((batch) => batch.LineId === line.Id) || null
  const order = getBatchWorkOrder(currentBatch)
  const product = getWorkOrderProduct(order)
  const lineEquipment = equipment.filter((item) => item.LineId === line.Id)
  const planned = getWorkOrderLots(order).reduce((sum, batch) => sum + (batch.PlannedQuantity || 0), 0)
  const completed = getWorkOrderLots(order).reduce((sum, batch) => sum + (batch.CompletedQuantity || 0), 0)
  return {
    LineCode: line.LineCode,
    LineName: line.LineName,
    Workshop: line.Workshop,
    Status: currentBatch?.Status === BATCH_STATUS_CODE.pending ? 2 : 1,
    WorkOrderCode: order?.WorkOrderCode || '-',
    LotCode: currentBatch?.LotCode || '-',
    ProductCode: product?.ProductCode || '-',
    ProductName: product?.ProductName || '-',
    PlannedQuantity: planned,
    CompletedQuantity: completed,
    EquipmentStatuses: lineEquipment.map((item) => DEVICE_STATUS_KEY[item.Status] || item.Status),
    Oee: 86.4,
    DueTime: currentBatch?.EstimatedCompletionTime?.slice(11, 16) || '-',
    AlertCount: 0,
  }
}

export function getLineDashboardRows() {
  return lines.map(getLineDashboard)
}

export function getBomDisplayItems(productId = 1) {
  const activeBom = boms.find((item) => item.ProductId === productId && item.IsActive === 1)
  if (!activeBom) return []
  return bomItems
    .filter((item) => item.BomId === activeBom.Id)
    .map((item) => {
      const material = materials.find((materialItem) => materialItem.Id === item.MaterialId)
      const substitutes = materialSubstitutes
        .filter((substitute) => substitute.MaterialId === item.MaterialId)
        .map((substitute) => materials.find((materialItem) => materialItem.Id === substitute.SubstituteMaterialId)?.MaterialCode)
        .filter(Boolean)
      return {
        ...item,
        MaterialCode: material?.MaterialCode || '-',
        MaterialDesc: material?.MaterialDesc || '-',
        SubstituteMaterialCodes: substitutes.join(',') || '-',
      }
    })
}

function requiredQuantityForLot(bomItem, batch) {
  return (bomItem.Quantity || 0) * (batch?.PlannedQuantity || 0)
}

export function getBatchLoadingTasks(lotCode) {
  const batch = findBatch(lotCode)
  if (!batch) return []
  const product = getBatchProduct(batch)
  const activeBom = boms.find((item) => item.ProductId === product?.Id && item.IsActive === 1)
  if (!activeBom) return []
  const firstStep = getRouteFirstStep(getBatchWorkOrder(batch)?.RouteId)
  return bomItems
    .filter((item) => item.BomId === activeBom.Id)
    .map((item, index) => {
      const material = materials.find((materialItem) => materialItem.Id === item.MaterialId)
      const substitutes = materialSubstitutes
        .filter((substitute) => substitute.MaterialId === item.MaterialId)
        .map((substitute) => materials.find((materialItem) => materialItem.Id === substitute.SubstituteMaterialId)?.MaterialCode)
        .filter(Boolean)
      const allowedMaterialIds = [
        item.MaterialId,
        ...materialSubstitutes
          .filter((substitute) => substitute.MaterialId === item.MaterialId)
          .map((substitute) => substitute.SubstituteMaterialId),
      ]
      const records = loadingRecords
        .filter((record) => record.LotId === batch.Id && allowedMaterialIds.includes(record.MaterialId))
        .sort((a, b) => String(b.LoadingTime).localeCompare(String(a.LoadingTime)))
      const loaded = records.reduce((sum, record) => sum + (record.ActualQuantity || 0), 0)
      const required = requiredQuantityForLot(item, batch)
      const hasFailedRecord = records.some((record) => record.VerifyStatus === VERIFY_STATUS_CODE.failed)
      return {
        BomItemId: item.Id,
        LotId: batch.Id,
        LotCode: batch.LotCode,
        RouteStepId: firstStep?.Id || null,
        StationCode: `F-${String(index + 1).padStart(3, '0')}`,
        MaterialId: item.MaterialId,
        MaterialCode: material?.MaterialCode || '-',
        MaterialDesc: material?.MaterialDesc || '-',
        PackageType: item.PackageType,
        MaterialPackageType: material?.PackageType || '-',
        Brand: material?.Brand || '-',
        RequiredQuantity: required,
        LoadedQuantity: loaded,
        VerifyStatus: hasFailedRecord ? VERIFY_STATUS_CODE.failed : loaded >= required ? VERIFY_STATUS_CODE.passed : VERIFY_STATUS_CODE.pending,
        SubstituteMaterialCodes: substitutes.join(',') || '-',
        LoadingRecords: records,
      }
    })
}

export function fillBatchMaterial(lotCode, payload) {
  const batch = findBatch(lotCode)
  if (!batch) return { ok: false, message: '批次不存在。' }
  const tasks = getBatchLoadingTasks(lotCode)
  const target = tasks.find((item) => item.StationCode === payload.StationCode || item.StationCode === payload.station)
  if (!target) return { ok: false, message: '站位不存在。' }

  const scannedCode = String(payload.MaterialCode || payload.materialCode || '').trim()
  if (!scannedCode) return { ok: false, message: '物料条码不能为空。' }

  const allowedMaterials = [target.MaterialCode]
  if (target.SubstituteMaterialCodes && target.SubstituteMaterialCodes !== '-') {
    allowedMaterials.push(...String(target.SubstituteMaterialCodes).split(/[,，]/).map((item) => item.trim()).filter(Boolean))
  }
  const matchedCode = allowedMaterials.find((materialCode) => scannedCode === materialCode || scannedCode.startsWith(`${materialCode}#`))
  if (!matchedCode) {
    return {
      ok: false,
      message: `物料不匹配：站位 ${target.StationCode} 需要 ${target.MaterialCode}${target.SubstituteMaterialCodes !== '-' ? `，允许替代料 ${target.SubstituteMaterialCodes}` : ''}。`,
    }
  }

  const material = materials.find((item) => item.MaterialCode === matchedCode)
  const actualQuantity = Math.max(Number(payload.ActualQuantity ?? payload.loaded) || 0, 0)
  if (actualQuantity <= 0) return { ok: false, message: '上料数量必须大于 0。' }

  const operator = findUser(payload.OperatorId || payload.operator) || users[2]
  const routeStepId = target.RouteStepId
  const equipmentId = payload.EquipmentId || equipment.find((item) => item.LineId === batch.LineId)?.Id || 1
  const nextRecord = {
    Id: Date.now(),
    LotId: batch.Id,
    RouteStepId: routeStepId,
    EquipmentId: equipmentId,
    MaterialId: material?.Id || target.MaterialId,
    OperatorId: operator.Id,
    LoadingTime: payload.LoadingTime || payload.loadedAt || nowText(),
    ActualQuantity: actualQuantity,
    VerifyStatus: VERIFY_STATUS_CODE.passed,
    VerifyRemark: '',
    ...auditFields(payload.LoadingTime || payload.loadedAt || nowText(), '扫码上料'),
  }
  loadingRecords.unshift(nextRecord)
  if (validateBatchLoading(lotCode).pass) clearBatchLoadingRequest(lotCode)
  return { ok: true, task: getBatchLoadingTasks(lotCode).find((item) => item.BomItemId === target.BomItemId), record: nextRecord }
}

// 基于工站的上料记录（不关联批次）
// 用于"上料管理"流程简化后的场景：直接选择工站 → 扫码上料
// 参数：{ routeStepId, stationId, equipmentId, barcode, loadingQuantity, operatorId }
export function addStationLoadingRecord(payload) {
  const routeStepId = payload.routeStepId
  const stationId = payload.stationId
  const equipmentId = payload.equipmentId
  const barcode = String(payload.barcode || '').trim()
  const actualQuantity = Math.max(Number(payload.loadingQuantity) || 0, 0)

  if (!routeStepId || !stationId) return { ok: false, message: '工站信息缺失。' }
  if (!barcode) return { ok: false, message: '物料批次条码不能为空。' }
  if (actualQuantity <= 0) return { ok: false, message: '上料数量必须大于 0。' }

  const materialLot = materialLots.find((lot) => lot.Barcode === barcode)
  if (!materialLot) return { ok: false, message: '物料批次不存在。' }

  const material = materials.find((m) => m.MaterialCode === materialLot.MaterialCode)
  const operator = findUser(payload.operatorId) || users[2]
  const nextRecord = {
    Id: Date.now(),
    LotId: null,
    StationId: stationId,
    RouteStepId: routeStepId,
    EquipmentId: equipmentId,
    MaterialId: material?.Id || null,
    MaterialLotId: materialLot.Id,
    OperatorId: operator.Id,
    LoadingTime: payload.loadingTime || nowText(),
    ActualQuantity: actualQuantity,
    VerifyStatus: VERIFY_STATUS_CODE.passed,
    VerifyRemark: '',
    ...auditFields(payload.loadingTime || nowText(), '扫码上料（工站直选）'),
  }
  loadingRecords.unshift(nextRecord)
  // 扣减库存
  consumeMaterialLot(barcode, actualQuantity)
  return { ok: true, record: nextRecord }
}

export function getBatchLoadingSummary(lotCode) {
  const tasks = getBatchLoadingTasks(lotCode)
  const finished = tasks.filter((item) => item.LoadedQuantity >= item.RequiredQuantity).length
  return {
    TotalCount: tasks.length,
    FinishedCount: finished,
    Percentage: tasks.length ? Math.round((finished / tasks.length) * 100) : 0,
    total: tasks.length,
    finished,
    percentage: tasks.length ? Math.round((finished / tasks.length) * 100) : 0,
  }
}

export function validateBatchLoading(lotCode) {
  const tasks = getBatchLoadingTasks(lotCode)
  const missing = tasks.filter((item) => item.LoadedQuantity < item.RequiredQuantity)
  return {
    pass: missing.length === 0,
    missing,
    message: missing.length === 0 ? 'BOM 上料校验通过。' : `仍有 ${missing.length} 个站位未齐套。`,
  }
}

export function requestBatchLoading(lotCode, reason = '进站 BOM 校验未通过') {
  const batch = findBatch(lotCode)
  if (!batch) return { ok: false, message: '批次不存在。' }
  batchLoadingRequestState[lotCode] = {
    LotCode: lotCode,
    LotId: batch.Id,
    Reason: reason,
    RequestedAt: nowText(),
  }
  return { ok: true, request: batchLoadingRequestState[lotCode] }
}

export function clearBatchLoadingRequest(lotCode) {
  delete batchLoadingRequestState[lotCode]
}

export function hasBatchLoadingRequest(lotCode) {
  return Boolean(batchLoadingRequestState[lotCode])
}

export const loadingTasks = getBatchLoadingTasks('B20260512005-01')

export const processTimeline = [
  { RouteStepId: 101, OperationName: '印刷', StationInTime: '08:42', StationOutTime: '09:02', StationInQuantity: 600, DefectQuantity: 0, OperatorName: '张工', EquipmentCode: 'PRT-A1-01', Result: '通过' },
  { RouteStepId: 102, OperationName: 'SPI 检测', StationInTime: '09:05', StationOutTime: '09:28', StationInQuantity: 596, DefectQuantity: 4, OperatorName: '张工', EquipmentCode: 'SPI-A1-01', Result: '通过' },
  { RouteStepId: 103, OperationName: '贴片', StationInTime: '09:33', StationOutTime: '11:40', StationInQuantity: 590, DefectQuantity: 6, OperatorName: '周工', EquipmentCode: 'MNT-A1-01', Result: '通过' },
  { RouteStepId: 104, OperationName: '回流焊接', StationInTime: '11:50', StationOutTime: '12:20', StationInQuantity: 586, DefectQuantity: 4, OperatorName: '周工', EquipmentCode: 'RFL-A1-01', Result: '通过' },
  { RouteStepId: 105, OperationName: 'AOI 检测', StationInTime: '13:10', StationOutTime: '-', StationInQuantity: 528, DefectQuantity: 7, OperatorName: '张工', EquipmentCode: 'AOI-A1-01', Result: '已进站' },
]

export function dashboardMetrics() {
  const totalOrders = workOrders.length
  const inProcessBatches = batches.filter((item) => [BATCH_STATUS_CODE.running, BATCH_STATUS_CODE.paused, BATCH_STATUS_CODE.repair, BATCH_STATUS_CODE.locked].includes(item.Status)).length
  const planTotal = workOrders.reduce((sum, item) => sum + item.PlannedQuantity, 0)
  const completedTotal = batches.reduce((sum, item) => sum + item.CompletedQuantity, 0)
  const defective = batches.reduce((sum, item) => sum + getBatchDefectQuantity(item), 0)
  return {
    totalOrders,
    inProcessBatches,
    firstPassYield: Number((100 - (defective / Math.max(completedTotal, 1)) * 100).toFixed(1)),
    planCompletion: percent(completedTotal, planTotal),
  }
}

function setWorkOrderStatus(order, status) {
  if (!order) return
  order.Status = getStatusCode(WORK_ORDER_STATUS_CODE, status) || order.Status
  order.UpdatedAt = nowText()
  order.UpdatedBy = SYSTEM_USER_ID
}

function setBatchStatus(batch, status) {
  if (!batch) return
  batch.Status = getStatusCode(BATCH_STATUS_CODE, status) || batch.Status
  batch.UpdatedAt = nowText()
  batch.UpdatedBy = SYSTEM_USER_ID
}

function setBatchCompletedQuantity(batch, qty) {
  if (!batch) return
  batch.CompletedQuantity = qty
  batch.UpdatedAt = nowText()
}

function setBatchTiming(batch, payload = {}) {
  if (!batch) return
  if (payload.EstimatedCompletionTime !== undefined || payload.estimatedCompletionTime !== undefined) {
    batch.EstimatedCompletionTime = payload.EstimatedCompletionTime ?? payload.estimatedCompletionTime ?? null
  }
  if (payload.StartTime !== undefined || payload.startTime !== undefined) {
    batch.StartTime = payload.StartTime ?? payload.startTime ?? null
  }
  if (payload.EndTime !== undefined || payload.endTime !== undefined) {
    batch.EndTime = payload.EndTime ?? payload.endTime ?? null
  }
}

function ensureBatchExecutionState(lotCode) {
  if (!batchExecutionState[lotCode]) {
    batchExecutionState[lotCode] = {
      PendingQuantity: 0,
      CurrentInQuantity: 0,
      CurrentInTime: null,
      CurrentEquipmentId: null,
      CurrentOperatorId: null,
    }
  }
  return batchExecutionState[lotCode]
}

function ensureBatchTraceState(lotCode) {
  if (!batchTraceState[lotCode]) batchTraceState[lotCode] = []
  return batchTraceState[lotCode]
}

function pushBatchTrace(lotCode, payload) {
  const trace = ensureBatchTraceState(lotCode)
  trace.unshift({
    Id: `${lotCode}-${trace.length + 1}`,
    EventTime: payload.EventTime || payload.time || nowText(),
    EventType: payload.EventType || payload.type || 'status',
    RouteStepId: payload.RouteStepId || null,
    Quantity: payload.Quantity || payload.qty || 0,
    FinishedQuantity: payload.FinishedQuantity || payload.goodQty || 0,
    DefectQuantity: payload.DefectQuantity || payload.badQty || 0,
    ScrapQuantity: payload.ScrapQuantity || payload.scrapQty || 0,
    EquipmentId: payload.EquipmentId || null,
    OperatorId: payload.OperatorId || null,
    Message: payload.Message || payload.message || '',
  })
}

function createProcessRecord(batch, routeStep, status = 'wait_in', quantity = 0) {
  const record = {
    Id: Date.now(),
    LotId: batch.Id,
    RouteStepId: routeStep?.Id || null,
    Status: getStatusCode(PROCESS_STATUS_CODE, status),
    StationInTime: null,
    StationInQuantity: quantity,
    StationOutTime: null,
    FinishedQuantity: 0,
    DefectQuantity: 0,
    ...auditFields(nowText(), '创建工序状态'),
  }
  lotOperationStatus.push(record)
  return record
}

export function releaseBatchToFirstProcess(lotCode) {
  const batch = findBatch(lotCode)
  if (!batch) return { ok: false, message: '批次不存在。' }
  if (batch.Status !== BATCH_STATUS_CODE.pending) return { ok: false, message: '只有待生产批次可以投产。' }

  const order = getBatchWorkOrder(batch)
  const firstStep = getRouteFirstStep(order?.RouteId)
  if (!firstStep) return { ok: false, message: '未配置工艺路线。' }

  const state = ensureBatchExecutionState(batch.LotCode)
  createProcessRecord(batch, firstStep, 'wait_in', batch.PlannedQuantity)
  state.PendingQuantity = batch.PlannedQuantity
  setBatchStatus(batch, 'running')
  pushBatchTrace(batch.LotCode, {
    EventType: 'status',
    RouteStepId: firstStep.Id,
    Quantity: batch.PlannedQuantity,
    Message: `投产成功，生成首道工序 ${findOperation(firstStep.OperationId)?.OperationName || '-'} 待进站`,
    EventTime: nowText(),
  })
  return { ok: true, batch, process: getCurrentProcess(batch) }
}

export function submitBatchCheckIn(lotCode, payload) {
  const batch = findBatch(lotCode)
  if (!batch) return { ok: false, message: '批次不存在。' }

  const process = getCurrentProcess(batch)
  if (!process || process.Status !== PROCESS_STATUS_CODE.wait_in) return { ok: false, message: '当前工序不是待进站状态。' }

  const state = ensureBatchExecutionState(batch.LotCode)
  const stationInQuantity = Math.max(Number(payload.StationInQuantity ?? payload.qty) || 0, 0)
  if (stationInQuantity <= 0) return { ok: false, message: '进站数量必须大于 0。' }

  const equipmentItem = findEquipment(payload.EquipmentId || payload.deviceId)
  const operator = findUser(payload.OperatorId || payload.operator) || users[2]
  const stationInTime = payload.StationInTime || payload.inAt || nowText()

  state.PendingQuantity = 0
  state.CurrentInQuantity = stationInQuantity
  state.CurrentInTime = stationInTime
  state.CurrentEquipmentId = equipmentItem?.Id || null
  state.CurrentOperatorId = operator.Id

  process.Status = PROCESS_STATUS_CODE.checked_in
  process.StationInTime = stationInTime
  process.StationInQuantity = stationInQuantity
  process.UpdatedAt = stationInTime

  stationInRecords.unshift({
    Id: Date.now(),
    LotId: batch.Id,
    RouteStepId: process.RouteStepId,
    Round: 1,
    EquipmentId: equipmentItem?.Id || null,
    OperatorId: operator.Id,
    StationInTime: stationInTime,
    StationInQuantity: stationInQuantity,
    Status: 1,
    VerifyRemark: payload.VerifyRemark || payload.remark || '',
    ...auditFields(stationInTime, '进站'),
  })

  if (!batch.StartTime) setBatchTiming(batch, { StartTime: stationInTime })
  setBatchStatus(batch, 'running')

  pushBatchTrace(batch.LotCode, {
    EventType: 'checkin',
    RouteStepId: process.RouteStepId,
    Quantity: stationInQuantity,
    EquipmentId: equipmentItem?.Id || null,
    OperatorId: operator.Id,
    Message: `${getCurrentOperationName(batch)} 已进站`,
    EventTime: stationInTime,
  })

  return { ok: true, batch }
}

export function submitBatchCheckOut(lotCode, payload) {
  const batch = findBatch(lotCode)
  if (!batch) return { ok: false, message: '批次不存在。' }

  const process = getCurrentProcess(batch)
  if (!process || process.Status !== PROCESS_STATUS_CODE.checked_in) return { ok: false, message: '当前工序不是已进站状态，不能出站。' }

  const state = ensureBatchExecutionState(batch.LotCode)
  const operationName = getCurrentOperationName(batch)
  const isInspection = isInspectionProcess(operationName)
  const stationOutTime = payload.StationOutTime || payload.outAt || nowText()
  const operator = findUser(payload.OperatorId || payload.operator) || users[2]

  let finishedQuantity = 0
  let defectQuantity = 0
  let scrapQuantity = 0
  let disposalType = payload.DisposalType || DISPOSAL_TYPE_CODE[payload.disposal] || null
  let disposalRemark = payload.DisposalRemark || payload.remark || ''
  let isNormal = 1

  if (isInspection) {
    const passRate = Math.max(0, Math.min(100, Number(payload.SpiPassRate ?? payload.AoiPassRate ?? payload.passRate) || 0))
    const threshold = getInspectionThreshold(operationName)
    const action = passRate >= threshold ? 'normal' : payload.qualityAction

    if (passRate < threshold && !['force', 'lock'].includes(action)) {
      return { ok: false, message: `检测通过率 ${passRate}% 低于阈值 ${threshold}%，请选择强制出站或批次锁定。` }
    }
    if (passRate < threshold && !String(disposalRemark || '').trim()) {
      return { ok: false, message: action === 'lock' ? '请填写批次锁定原因。' : '请填写强制出站原因。' }
    }

    if (passRate < threshold && action === 'lock') {
      process.Status = PROCESS_STATUS_CODE.locked
      process.StationOutTime = stationOutTime
      setBatchStatus(batch, 'locked')
      batchLockState[batch.LotCode] = {
        ...(batchLockState[batch.LotCode] || {}),
        LockReason: disposalRemark || `${operationName} 通过率 ${passRate}% 低于阈值 ${threshold}%`,
        AutoLocked: true,
      }
      pushBatchTrace(batch.LotCode, {
        EventType: 'quality',
        RouteStepId: process.RouteStepId,
        Message: `${operationName} 通过率 ${passRate}% 低于阈值 ${threshold}%，批次已锁定，等待质量评审`,
        EventTime: stationOutTime,
        OperatorId: operator.Id,
      })
      return { ok: true, batch, nextStep: operationName, status: 'locked' }
    }

    finishedQuantity = state.CurrentInQuantity
    defectQuantity = 0
    scrapQuantity = 0
    disposalType = action === 'force' ? DISPOSAL_TYPE_CODE.force : null
    isNormal = passRate >= threshold || action === 'force' ? 1 : 0

    stationOutRecords.unshift({
      Id: Date.now(),
      LotId: batch.Id,
      RouteStepId: process.RouteStepId,
      Round: 1,
      OperatorId: operator.Id,
      StationOutTime: stationOutTime,
      FinishedQuantity: finishedQuantity,
      DefectQuantity: defectQuantity,
      IsNormal: isNormal,
      DisposalType: disposalType,
      DisposalRemark: disposalRemark,
      SpiPassRate: operationName.includes('SPI') ? passRate : null,
      AoiPassRate: operationName.includes('AOI') ? passRate : null,
      ...auditFields(stationOutTime, '检测出站'),
    })
  } else {
    finishedQuantity = Math.max(Number(payload.FinishedQuantity ?? payload.goodQty) || 0, 0)
    defectQuantity = Math.max(Number(payload.DefectQuantity ?? payload.badQty) || 0, 0)
    if (defectQuantity > 0 && !disposalType) disposalType = DISPOSAL_TYPE_CODE.repair
    scrapQuantity = disposalType === DISPOSAL_TYPE_CODE.scrap ? defectQuantity : 0
    const totalQuantity = finishedQuantity + defectQuantity
    if (totalQuantity !== state.CurrentInQuantity) {
      return { ok: false, message: `数量不匹配：进站数量 ${state.CurrentInQuantity}，出站合计 ${totalQuantity}。` }
    }
    isNormal = defectQuantity === 0 ? 1 : 0

    stationOutRecords.unshift({
      Id: Date.now(),
      LotId: batch.Id,
      RouteStepId: process.RouteStepId,
      Round: 1,
      OperatorId: operator.Id,
      StationOutTime: stationOutTime,
      FinishedQuantity: finishedQuantity,
      DefectQuantity: defectQuantity,
      ScrapQuantity: scrapQuantity,
      IsNormal: isNormal,
      DisposalType: disposalType,
      DisposalRemark: disposalRemark,
      SpiPassRate: null,
      AoiPassRate: null,
      ...auditFields(stationOutTime, '出站'),
    })
  }

  setBatchCompletedQuantity(batch, finishedQuantity)
  process.Status = PROCESS_STATUS_CODE.checked_out
  process.StationOutTime = stationOutTime
  process.FinishedQuantity = finishedQuantity
  process.DefectQuantity = defectQuantity
  process.UpdatedAt = stationOutTime

  pushBatchTrace(batch.LotCode, {
    EventType: 'checkout',
    RouteStepId: process.RouteStepId,
    Quantity: finishedQuantity + defectQuantity,
    FinishedQuantity: finishedQuantity,
    DefectQuantity: defectQuantity,
    ScrapQuantity: scrapQuantity,
    OperatorId: operator.Id,
    Message: `${operationName} 已出站`,
    EventTime: stationOutTime,
  })

  state.CurrentInQuantity = 0
  state.CurrentEquipmentId = null
  state.CurrentOperatorId = null

  if (defectQuantity > 0 && disposalType === DISPOSAL_TYPE_CODE.repair) {
    setBatchStatus(batch, 'repair')
    repairTasks.unshift({
      Id: Date.now(),
      LotId: batch.Id,
      RouteStepId: process.RouteStepId,
      Status: REPAIR_STATUS_CODE.pending,
      RepairQuantity: defectQuantity,
      RepairedQuantity: 0,
      ScrapQuantity: 0,
      RepairDescription: disposalRemark || '待维修确认',
      RepairResult: null,
      RepairBy: null,
      RepairStartTime: null,
      RepairEndTime: null,
      ...auditFields(stationOutTime, '出站生成维修任务'),
    })
    pushBatchTrace(batch.LotCode, {
      EventType: 'repair',
      RouteStepId: process.RouteStepId,
      DefectQuantity: defectQuantity,
      Message: `已生成维修任务，数量 ${defectQuantity}`,
      EventTime: stationOutTime,
    })
    return { ok: true, batch, nextStep: operationName, status: 'repair' }
  }

  const order = getBatchWorkOrder(batch)
  const routeRows = getRouteStepRows(order?.RouteId)
  const stepIndex = routeRows.findIndex((item) => item.Id === process.RouteStepId)
  const nextStep = stepIndex >= 0 && stepIndex < routeRows.length - 1 ? routeRows[stepIndex + 1] : null

  if (nextStep) {
    createProcessRecord(batch, nextStep, 'wait_in', finishedQuantity)
    state.PendingQuantity = finishedQuantity
    pushBatchTrace(batch.LotCode, {
      EventType: 'status',
      RouteStepId: nextStep.Id,
      Quantity: finishedQuantity,
      Message: `流转至下一工序 ${nextStep.OperationName}，等待进站`,
      EventTime: stationOutTime,
    })
    return { ok: true, batch, nextStep: nextStep.OperationName, status: 'wait_in' }
  }

  setBatchStatus(batch, 'completed')
  setBatchTiming(batch, { EndTime: stationOutTime })
  state.PendingQuantity = 0
  pushBatchTrace(batch.LotCode, {
    EventType: 'status',
    RouteStepId: process.RouteStepId,
    Quantity: finishedQuantity,
    Message: '批次全部工序完成',
    EventTime: stationOutTime,
  })
  return { ok: true, batch, nextStep: '', status: 'completed' }
}

export function submitRepairResult(lotCode, payload) {
  const batch = findBatch(lotCode)
  if (!batch) return { ok: false, message: '批次不存在。' }

  const task = repairTasks.find((item) => item.LotId === batch.Id && item.Status !== REPAIR_STATUS_CODE.completed)
  const state = ensureBatchExecutionState(batch.LotCode)
  const repairedQuantity = Math.max(Number(payload.RepairedQuantity ?? payload.repairQty) || 0, 0)
  const scrapQuantity = Math.max(Number(payload.ScrapQuantity ?? payload.scrapQty) || 0, 0)
  const completedAt = payload.RepairEndTime || payload.completedAt || nowText()
  const repairBy = findUser(payload.RepairBy || payload.handler) || users[3]

  if (task) {
    task.Status = REPAIR_STATUS_CODE.completed
    task.RepairResult = payload.RepairResult || (payload.result === 'repair_pass' ? 1 : 2)
    task.RepairedQuantity = repairedQuantity
    task.ScrapQuantity = scrapQuantity
    task.RepairBy = repairBy.Id
    task.RepairEndTime = completedAt
    task.UpdatedAt = completedAt
  }

  if (payload.result === 'repair_pass' || payload.RepairResult === 1) {
    setBatchStatus(batch, 'running')
    state.PendingQuantity = repairedQuantity
    const process = getCurrentProcess(batch)
    if (process) process.Status = PROCESS_STATUS_CODE.wait_in
    pushBatchTrace(batch.LotCode, {
      EventType: 'repair',
      RouteStepId: process?.RouteStepId || null,
      Quantity: repairedQuantity,
      Message: `维修完成，返回 ${getCurrentOperationName(batch)} 待进站`,
      EventTime: completedAt,
    })
    return { ok: true, batch, status: 'wait_in' }
  }

  setBatchStatus(batch, 'completed')
  state.PendingQuantity = 0
  pushBatchTrace(batch.LotCode, {
    EventType: 'repair',
    RouteStepId: getCurrentProcess(batch)?.RouteStepId || null,
    ScrapQuantity: scrapQuantity,
    Message: '维修结束，批次关闭',
    EventTime: completedAt,
  })
  return { ok: true, batch, status: 'completed' }
}

export function getInspectionThreshold(operationName = '') {
  const product = products[0]
  if (operationName.includes('SPI')) return product?.SpiThreshold ?? 97
  if (operationName.includes('AOI')) return product?.AoiThreshold ?? 96
  return 0
}

export function inspectionTypeByStep(operationName = '') {
  if (operationName.includes('SPI') || operationName.includes('spi')) return 'SPI'
  if (operationName.includes('AOI') || operationName.includes('aoi') || operationName.includes('光学检测')) return 'AOI'
  return ''
}

export function isInspectionProcess(operationName = '') {
  return Boolean(inspectionTypeByStep(operationName))
}

export function getBatchTrace(lotCode) {
  return ensureBatchTraceState(lotCode).map((item) => {
    const routeStep = findRouteStep(item.RouteStepId)
    const operation = findOperation(routeStep?.OperationId)
    const equipmentItem = findEquipment(item.EquipmentId)
    const operator = findUser(item.OperatorId)
    return {
      ...item,
      OperationName: operation?.OperationName || '-',
      EquipmentCode: equipmentItem?.EquipmentCode || '',
      OperatorName: operator?.FullName || '',
    }
  })
}

// ==================== 物料批次管理辅助函数 ====================

// 按 ID/条码/批次号查找物料批次
export function findMaterialLot(idOrBarcode) {
  if (!idOrBarcode) return null
  const key = String(idOrBarcode).trim()
  return materialLots.find(
    (item) => String(item.Id) === key || item.Barcode === key || item.BatchNo === key,
  ) || null
}

// 按物料编码查找所有批次
export function findMaterialLotsByMaterialCode(materialCode) {
  if (!materialCode) return []
  return materialLots.filter((item) => item.MaterialCode === materialCode)
}

// 带筛选的物料批次列表查询
export function getMaterialLotList(filters = {}) {
  let list = [...materialLots]
  if (filters.MaterialCode) {
    list = list.filter((item) => item.MaterialCode === filters.MaterialCode)
  }
  if (filters.Status) {
    list = list.filter((item) => item.Status === filters.Status)
  }
  if (filters.Supplier) {
    const kw = String(filters.Supplier).toLowerCase()
    list = list.filter((item) => String(item.Supplier || '').toLowerCase().includes(kw))
  }
  if (filters.BatchNo) {
    const kw = String(filters.BatchNo).toLowerCase()
    list = list.filter((item) => String(item.BatchNo || '').toLowerCase().includes(kw) || String(item.Barcode || '').toLowerCase().includes(kw))
  }
  // 有效期范围筛选
  if (filters.ExpiryDateStart) {
    list = list.filter((item) => item.ExpiryDate && String(item.ExpiryDate) >= filters.ExpiryDateStart)
  }
  if (filters.ExpiryDateEnd) {
    list = list.filter((item) => item.ExpiryDate && String(item.ExpiryDate) <= filters.ExpiryDateEnd)
  }
  // 入库日期范围筛选
  if (filters.InboundDateStart) {
    list = list.filter((item) => String(item.InboundDate || '').slice(0, 10) >= filters.InboundDateStart)
  }
  if (filters.InboundDateEnd) {
    list = list.filter((item) => String(item.InboundDate || '').slice(0, 10) <= filters.InboundDateEnd)
  }
  // 过期状态筛选
  if (filters.ExpiryStatus === 'expired') {
    const today = new Date().toISOString().slice(0, 10)
    list = list.filter((item) => item.ExpiryDate && String(item.ExpiryDate) < today)
  } else if (filters.ExpiryStatus === 'valid') {
    const today = new Date().toISOString().slice(0, 10)
    list = list.filter((item) => !item.ExpiryDate || String(item.ExpiryDate) >= today)
  }
  // 默认按入库日期倒序
  list.sort((a, b) => String(b.InboundDate).localeCompare(String(a.InboundDate)))
  return list
}

// 本地创建物料批次（BatchNo 和 Barcode 由后端生成，Mock 模式下本地生成）
export function createMaterialLot(payload) {
  const material = materials.find((item) => item.MaterialCode === payload.MaterialCode)
  if (!material) return { ok: false, message: '物料编码不存在' }
  const quantity = Number(payload.Quantity) || 0
  if (quantity <= 0) return { ok: false, message: '入库数量必须大于 0' }

  const newId = materialLots.length ? Math.max(...materialLots.map((item) => item.Id)) + 1 : 1
  // Mock 模式下本地生成 BatchNo 和 Barcode（真实环境由后端返回）
  const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '')
  const seq = String(materialLots.filter((item) => item.MaterialCode === payload.MaterialCode).length + 1).padStart(2, '0')
  const batchNo = `LOT${dateStr}-${seq}`
  const barcode = `${payload.MaterialCode}#${batchNo}`

  const newLot = {
    Id: newId,
    MaterialCode: payload.MaterialCode,
    BatchNo: batchNo,
    Supplier: payload.Supplier || '',
    SupplierBatchNo: payload.SupplierBatchNo || '',
    Quantity: quantity,
    UsedQuantity: 0,
    ProductionDate: payload.ProductionDate || null,
    ExpiryDate: payload.ExpiryDate || null,
    MslLevel: payload.MslLevel || null,
    InboundDate: payload.InboundDate || nowText(),
    Status: '在库',
    Barcode: barcode,
    ...auditFields(nowText(), '物料入库'),
  }
  materialLots.unshift(newLot)
  return { ok: true, lot: newLot }
}

// 修改物料批次状态
export function updateMaterialLotStatus(id, status) {
  const lot = materialLots.find((item) => item.Id === id)
  if (!lot) return { ok: false, message: '物料批次不存在' }
  if (lot.Status === '已使用') return { ok: false, message: '已使用状态不可变更' }
  lot.Status = status
  lot.UpdatedAt = nowText()
  lot.LastOperationType = 'UPDATE'
  lot.LastOperationRemark = `状态变更为${status}`
  return { ok: true, lot }
}

// 扣减物料批次库存
export function consumeMaterialLot(barcode, quantity) {
  const lot = findMaterialLot(barcode)
  if (!lot) return { ok: false, message: '条码无效，物料批次不存在' }
  const consumeQty = Number(quantity) || 0
  const remaining = lot.Quantity - lot.UsedQuantity
  if (consumeQty <= 0) return { ok: false, message: '扣减数量必须大于 0' }
  if (consumeQty > remaining) return { ok: false, message: `物料批次剩余 ${remaining}，不足需要的 ${consumeQty}` }
  lot.UsedQuantity += consumeQty
  if (lot.UsedQuantity >= lot.Quantity) {
    lot.Status = '已使用'
  }
  lot.UpdatedAt = nowText()
  lot.LastOperationType = 'UPDATE'
  lot.LastOperationRemark = `上料消耗 ${consumeQty}`
  return { ok: true, lot }
}

// 获取指定工站（RouteStepId）的已上料物料批次记录
// 字段对齐 smt_loading_records 表结构：LotId, StationId, MaterialLotId, OperatorId, LoadingTime, VerifyStatus, VerifyRemark
export function getStationLoadingRecords(routeStepId, lotId = null) {
  let records = loadingRecords.filter((item) => item.RouteStepId === routeStepId)
  if (lotId) {
    records = records.filter((item) => item.LotId === lotId)
  }
  return records.map((rec) => {
    // 通过 MaterialLotId 关联物料批次
    const materialLot = materialLots.find((ml) => ml.Id === rec.MaterialLotId)
    const material = materialLot
      ? materials.find((m) => m.MaterialCode === materialLot.MaterialCode)
      : materials.find((m) => m.Id === rec.MaterialId)
    const operator = findUser(rec.OperatorId)
    const station = findStation(rec.StationId)
    // 校验状态文案
    const verifyStatusText = { 0: '未校验', 1: '校验通过', 2: '校验失败' }[rec.VerifyStatus] || '未校验'
    const verifyStatusTag = { 0: 'info', 1: 'success', 2: 'danger' }[rec.VerifyStatus] || 'info'
    return {
      Id: rec.Id,
      LotId: rec.LotId,
      StationId: rec.StationId,
      MaterialLotId: rec.MaterialLotId,
      OperatorId: rec.OperatorId,
      LoadingTime: rec.LoadingTime || rec.CreatedAt || '-',
      VerifyStatus: rec.VerifyStatus,
      VerifyStatusText: verifyStatusText,
      VerifyStatusTag: verifyStatusTag,
      VerifyRemark: rec.VerifyRemark || '',
      // 关联展示字段
      MaterialCode: material?.MaterialCode || '-',
      MaterialDesc: material?.MaterialDesc || '-',
      PackageType: material?.PackageType || '-',
      Barcode: materialLot?.Barcode || '-',
      BatchNo: materialLot?.BatchNo || '-',
      Supplier: materialLot?.Supplier || '-',
      SupplierBatchNo: materialLot?.SupplierBatchNo || '-',
      ExpiryDate: materialLot?.ExpiryDate || '-',
      MaterialLotStatus: materialLot?.Status || '-',
      ActualQuantity: rec.ActualQuantity || 0,
      OperatorName: operator?.FullName || '-',
      StationCode: station?.StationCode || '-',
      StationName: station?.StationName || '-',
    }
  })
}

// ==================== 下料管理 Mock 函数 ====================

// 下料原因枚举（与数据库 smt_unloading_records.Reason tinyint 对齐）
// 1-批次完工换线 / 2-物料耗尽 / 3-品质异常 / 4-其他
// 注：用户需求中的"上错料"和"进站校验失败"两种场景归并到 4-其他，通过 Remark 备注说明
export const UNLOAD_REASON = {
  BATCH_CHANGE: { code: 1, label: '批次完工换线' },
  MATERIAL_DEPLETED: { code: 2, label: '物料耗尽' },
  QUALITY_ISSUE: { code: 3, label: '品质异常' },
  OTHER: { code: 4, label: '其他' },
}

// 下料原因 code → label 映射（便于历史记录展示）
export const UNLOAD_REASON_TEXT = {
  1: '批次完工换线',
  2: '物料耗尽',
  3: '品质异常',
  4: '其他',
}

// 下料场景细分（用于"其他"原因下的备注快速选择，仅为前端便捷录入，不入库）
export const UNLOAD_OTHER_SCENE = {
  WRONG_MATERIAL: '上错料',
  CHECK_IN_FAILED: '进站校验失败',
}

// 计算指定上料记录的可下料数量（上料数量 - 已下料数量）
export function getUnloadableQuantity(loadingRecordId) {
  const loaded = loadingRecords.find((r) => r.Id === loadingRecordId)
  if (!loaded) return 0
  const unloaded = unloadingRecords
    .filter((r) => r.LoadingRecordId === loadingRecordId)
    .reduce((sum, r) => sum + (r.UnloadQuantity || 0), 0)
  return Math.max((loaded.ActualQuantity || 0) - unloaded, 0)
}

// 获取工站可下料的上料记录（可下料数量 > 0）
export function getStationUnloadableRecords(routeStepId) {
  const records = getStationLoadingRecords(routeStepId, null)
  return records
    .map((rec) => ({
      ...rec,
      UnloadableQuantity: getUnloadableQuantity(rec.Id),
    }))
    .filter((rec) => rec.UnloadableQuantity > 0)
}

// 创建下料记录，同时回退物料批次库存
// 字段对齐数据库 smt_unloading_records：
//   payload: { loadingRecordId, unloadQuantity, reasonCode, remark, operatorId }
//   reasonCode: 1-批次完工换线 / 2-物料耗尽 / 3-品质异常 / 4-其他
//   remark: 下料备注（"其他"原因时必填，建议说明上错料/进站校验失败等具体场景）
export function addUnloadingRecord(payload) {
  const loadingRecordId = payload.loadingRecordId
  const unloadQuantity = Math.max(Number(payload.unloadQuantity) || 0, 0)

  if (!loadingRecordId) return { ok: false, message: '缺少关联的上料记录 ID。' }
  const loadingRecord = loadingRecords.find((r) => r.Id === loadingRecordId)
  if (!loadingRecord) return { ok: false, message: '关联的上料记录不存在。' }
  if (unloadQuantity <= 0) return { ok: false, message: '下料数量必须大于 0。' }

  const unloadable = getUnloadableQuantity(loadingRecordId)
  if (unloadQuantity > unloadable) {
    return { ok: false, message: `下料数量超过可下料数量（${unloadable}）。` }
  }

  // 下料原因校验：必须是 1-4 的有效 code
  const reasonCode = Number(payload.reasonCode)
  if (![1, 2, 3, 4].includes(reasonCode)) {
    return { ok: false, message: '请选择有效的下料原因。' }
  }
  // "4-其他"原因必须填写备注（用于说明上错料/进站校验失败等具体场景）
  if (reasonCode === 4 && !String(payload.remark || '').trim()) {
    return { ok: false, message: '选择"其他"原因时必须填写备注（说明上错料/进站校验失败等）。' }
  }

  const operator = findUser(payload.operatorId) || users[2]
  const materialLot = materialLots.find((ml) => ml.Id === loadingRecord.MaterialLotId)

  // 数据库实际字段（对齐 smt_unloading_records 表结构）
  const nextRecord = {
    Id: Date.now(),
    LoadingRecordId: loadingRecordId,
    LotId: loadingRecord.LotId || null,
    RouteStepId: loadingRecord.RouteStepId,
    EquipmentId: loadingRecord.EquipmentId || null,
    MaterialId: loadingRecord.MaterialId || null,
    // 数据库无 MaterialLotId 字段，但通过 LoadingRecordId 可间接关联，此处保留用于前端展示
    MaterialLotId: loadingRecord.MaterialLotId,
    UnloadingTime: nowText(),
    OperatorId: operator.Id,
    Reason: reasonCode,
    UnloadQuantity: unloadQuantity,
    InitialQuantity: loadingRecord.ActualQuantity || 0,
    ActualUsedQuantity: (loadingRecord.ActualQuantity || 0) - unloadable,
    RemainQuantity: unloadable - unloadQuantity,
    WastageQuantity: 0,
    Remark: payload.remark || '',
    ...auditFields(nowText(), '下料操作'),
  }
  unloadingRecords.unshift(nextRecord)

  // 回退物料批次库存
  if (materialLot) {
    materialLot.UsedQuantity = Math.max((materialLot.UsedQuantity || 0) - unloadQuantity, 0)
    materialLot.UpdatedAt = nowText()
    materialLot.LastOperationType = 'UNLOAD'
    materialLot.LastOperationRemark = `下料回退 ${unloadQuantity}`
  }

  return {
    ok: true,
    record: nextRecord,
    materialLotRemainingQuantity: materialLot
      ? (materialLot.Quantity || 0) - materialLot.UsedQuantity
      : null,
  }
}

// 查询工站下料记录列表
export function getStationUnloadingRecords(routeStepId) {
  return unloadingRecords
    .filter((r) => r.RouteStepId === routeStepId)
    .map((rec) => {
      const materialLot = materialLots.find((ml) => ml.Id === rec.MaterialLotId)
      const material = materialLot
        ? materials.find((m) => m.MaterialCode === materialLot.MaterialCode)
        : materials.find((m) => m.Id === rec.MaterialId)
      const operator = findUser(rec.OperatorId)
      const routeStep = routeSteps.find((rs) => rs.Id === rec.RouteStepId)
      const station = routeStep ? findStation(routeStep.StationId) : null
      return {
        Id: rec.Id,
        LoadingRecordId: rec.LoadingRecordId,
        RouteStepId: rec.RouteStepId,
        EquipmentId: rec.EquipmentId,
        MaterialId: rec.MaterialId,
        MaterialLotId: rec.MaterialLotId,
        OperatorId: rec.OperatorId,
        // 对齐数据库字段名
        UnloadingTime: rec.UnloadingTime || rec.CreatedAt || '-',
        UnloadQuantity: rec.UnloadQuantity || 0,
        Reason: rec.Reason,
        ReasonText: UNLOAD_REASON_TEXT[rec.Reason] || '-',
        Remark: rec.Remark || '',
        InitialQuantity: rec.InitialQuantity || 0,
        ActualUsedQuantity: rec.ActualUsedQuantity || 0,
        RemainQuantity: rec.RemainQuantity || 0,
        WastageQuantity: rec.WastageQuantity || 0,
        // 前端展示用关联字段
        MaterialCode: material?.MaterialCode || '-',
        MaterialDesc: material?.MaterialDesc || '-',
        PackageType: material?.PackageType || '-',
        Barcode: materialLot?.Barcode || '-',
        BatchNo: materialLot?.BatchNo || '-',
        Supplier: materialLot?.Supplier || '-',
        SupplierBatchNo: materialLot?.SupplierBatchNo || '-',
        ExpiryDate: materialLot?.ExpiryDate || '-',
        OperatorName: operator?.FullName || '-',
        StationCode: station?.StationCode || '-',
        StationName: station?.StationName || '-',
      }
    })
}

// 合并查询工站上下料历史（按时间倒序）
export function getStationLoadingAndUnloadingHistory(routeStepId) {
  const loading = getStationLoadingRecords(routeStepId, null).map((rec) => ({
    ...rec,
    RecordType: 'loading',
    RecordTypeText: '上料',
    RecordTypeTag: 'success',
    Quantity: rec.ActualQuantity || 0,
    QuantityLabel: `+${rec.ActualQuantity || 0}`,
    OperationTime: rec.LoadingTime,
    RelatedRecordId: null,
    Reason: '',
    ReasonText: '',
    Remark: '',
  }))
  const unloading = getStationUnloadingRecords(routeStepId).map((rec) => ({
    ...rec,
    RecordType: 'unloading',
    RecordTypeText: '下料',
    RecordTypeTag: 'warning',
    Quantity: rec.UnloadQuantity || 0,
    QuantityLabel: `-${rec.UnloadQuantity || 0}`,
    OperationTime: rec.UnloadingTime,
    RelatedRecordId: rec.LoadingRecordId,
    Reason: rec.ReasonText,
    Remark: rec.Remark,
  }))
  return [...loading, ...unloading]
    .sort((a, b) => String(b.OperationTime || '').localeCompare(String(a.OperationTime || '')))
}

// 获取设备类型支持的封装类型列表（PackageCode 数组）
export function getEquipmentSupportedPackages(equipmentTypeId) {
  const supported = equipmentPackageTypes.filter((item) => item.EquipmentTypeId === equipmentTypeId)
  return supported.map((item) => {
    const pkg = packageTypes.find((p) => p.Id === item.PackageTypeId)
    return pkg?.PackageCode || null
  }).filter(Boolean)
}

// 上料前完整校验（封装类型 + 物料状态 + 有效期 + 库存）
// equipmentTypeId: 当前工站设备类型 ID（用于封装类型校验）
export function validateMaterialLotForLoading(barcode, equipmentTypeId, requiredQty = 0) {
  // 1. 查找物料批次
  const lot = findMaterialLot(barcode)
  if (!lot) {
    return { ok: false, code: 'NOT_FOUND', message: '条码无效，请先在「物料批次管理」中创建物料批次' }
  }

  // 获取物料信息
  const material = materials.find((item) => item.MaterialCode === lot.MaterialCode)
  const materialPackageType = material?.PackageType || ''

  // 2. 封装类型校验
  if (equipmentTypeId) {
    const supportedPackages = getEquipmentSupportedPackages(equipmentTypeId)
    if (supportedPackages.length && !supportedPackages.includes(materialPackageType)) {
      return {
        ok: false,
        code: 'PACKAGE_MISMATCH',
        message: `封装类型不匹配：物料 ${lot.MaterialCode} 的封装 ${materialPackageType} 不被当前工站设备类型支持`,
        lot,
        supportedPackages,
        materialPackageType,
      }
    }
  }

  // 3. 物料状态校验
  if (lot.Status !== '在库') {
    return {
      ok: false,
      code: 'STATUS_INVALID',
      message: `物料批次状态为「${lot.Status}」，无法上料`,
      lot,
    }
  }

  // 4. 有效期校验
  if (lot.ExpiryDate) {
    const today = new Date()
    const expiry = new Date(lot.ExpiryDate)
    if (expiry < today) {
      return {
        ok: false,
        code: 'EXPIRED',
        message: `物料批次已过期（${lot.ExpiryDate}），无法上料`,
        lot,
      }
    }
  }

  // 5. 库存校验
  const remaining = lot.Quantity - lot.UsedQuantity
  if (requiredQty > 0 && remaining < requiredQty) {
    return {
      ok: false,
      code: 'INSUFFICIENT_QTY',
      message: `物料批次剩余 ${remaining}，不足需要的 ${requiredQty}`,
      lot,
    }
  }

  // 全部通过
  return {
    ok: true,
    code: 'PASS',
    message: '物料批次校验通过',
    lot,
    material,
    checks: {
      packageCheck: { pass: true, supportedPackages: equipmentTypeId ? getEquipmentSupportedPackages(equipmentTypeId) : [], materialPackageType },
      statusCheck: { pass: true, status: lot.Status },
      expiryCheck: { pass: true, expiryDate: lot.ExpiryDate },
      quantityCheck: { pass: true, remaining, requiredQty },
    },
  }
}
