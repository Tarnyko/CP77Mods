module CarDealer.System
import CarDealer.Classes.PurchasableVehicle
import CarDealer.Utils.P

public class PurchasableVehicleSystem extends ScriptableSystem {

  private let m_storeVehicles: array<ref<PurchasableVehicle>>;

  private let m_vehicleSystem: ref<VehicleSystem>;

  public final static func GetInstance(gameInstance: GameInstance) -> ref<PurchasableVehicleSystem> {
    let system: ref<PurchasableVehicleSystem> = GameInstance.GetScriptableSystemsContainer(gameInstance).Get(n"CarDealer.System.PurchasableVehicleSystem") as PurchasableVehicleSystem;
    return system;
  }

  private final func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
    let player: ref<PlayerPuppet> = GameInstance.GetPlayerSystem(request.owner.GetGame()).GetLocalPlayerMainGameObject() as PlayerPuppet;
    if IsDefined(player) {
      this.m_vehicleSystem = GameInstance.GetVehicleSystem(player.GetGame());
      this.PopulateVehicleList();
      P(s"PurchasableVehicleSystem initialized, detected vehicles: \(ArraySize(this.m_storeVehicles))");
    };
  }

  private func PopulateVehicleList() -> Void {
    let vehicles: array<ref<PurchasableVehicle>>;
    let purchaseable: ref<PurchasableVehicle>;
    for record in TweakDBInterface.GetRecords(n"Vehicle") {
      let vehicleRecord: ref<Vehicle_Record> = record as Vehicle_Record;
      let priceVariant: Variant = TweakDBInterface.GetFlat(vehicleRecord.GetID() + t".dealerPrice");
      let price: Int32 = FromVariant<Int32>(priceVariant);
      let dealerAtlasVariant: Variant;
      let dealerPartNameVariant: Variant;
      let id: TweakDBID = vehicleRecord.GetID();
      if NotEquals(price, 0) && !StrBeginsWith(TDBID.ToStringDEBUG(id), "AMM_") {
        dealerAtlasVariant = TweakDBInterface.GetFlat(id + t".dealerAtlasPath");
        dealerPartNameVariant = TweakDBInterface.GetFlat(id + t".dealerPartName");
        purchaseable = new PurchasableVehicle();
        purchaseable.record = vehicleRecord;
        purchaseable.price = price;
        purchaseable.dealerAtlasPath = ResRef.FromString(FromVariant<String>(dealerAtlasVariant));
        purchaseable.dealerPartName = StringToName(FromVariant<String>(dealerPartNameVariant));
        ArrayPush(vehicles, purchaseable);
        P(s" - vehicle detected: \(TDBID.ToStringDEBUG(id)) \(GetLocalizedTextByKey(vehicleRecord.DisplayName())): \(price) $");
      };
    };
    this.m_storeVehicles = vehicles;
  }

  public func GetList() -> array<ref<PurchasableVehicle>> {
    return this.m_storeVehicles;
  }

  public func IsPurchasable(id: TweakDBID) -> Bool {
    for vehicle in this.m_storeVehicles {
      if Equals(vehicle.record.GetID(), id) {
        return true;
      };
    };
    return false;
  }

  public func IsPurchased(id: TweakDBID) -> Bool {
    let unlockedVehicles: array<PlayerVehicle>;
    this.m_vehicleSystem.GetPlayerUnlockedVehicles(unlockedVehicles);
    for vehicle in unlockedVehicles {
      if Equals(vehicle.recordID, id) {
        return true;
      };
    };
    return false;
  }

  public func Purchase(id: TweakDBID) -> Void {
    this.m_vehicleSystem.EnablePlayerVehicle(TDBID.ToStringDEBUG(id), true, false);
  }

  public func BuyAll() -> Void {
    for vehicle in this.m_storeVehicles {
      this.Purchase(vehicle.record.GetID());
    };
  }

  public func IsInDangerZone(player: ref<PlayerPuppet>) -> Bool {
    let bb: ref<IBlackboard> = player.GetPlayerStateMachineBlackboard();
    let zone: Int32 = bb.GetInt(GetAllBlackboardDefs().PlayerStateMachine.Zones);
    let inDanger: Bool = zone > 2;
    P(s"Detected zone: \(zone)");
    return inDanger;
  }
}
