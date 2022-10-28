module EnhancedCraft.Naming
import EnhancedCraft.Codeware.UI.*
import EnhancedCraft.Common.L
import EnhancedCraft.Events.*
import EnhancedCraft.System.*

// -- Clear input field and refreshes input text visibility
@addMethod(CraftingMainGameController)
protected cb func OnEnhancedCraftRecipeClickedEvent(event: ref<EnhancedCraftRecipeClicked>) -> Bool {
  let visible: Bool = event.isClothes || event.isWeapon;
  this.m_nameInput.SetText("");
	this.m_nameInputContainer.SetVisible(visible);
  this.m_originalName = this.m_craftedItemName.GetText();
}

// -- Clear input field
@addMethod(CraftingMainGameController)
protected cb func OnEnhancedCraftRecipeVariantChanged(event: ref<EnhancedCraftRecipeVariantChanged>) -> Bool {
  this.m_nameInput.SetText("");
}

// -- Catch crafting events to persist custom name, clear input text and restore original recipe name
@addMethod(CraftingMainGameController)
protected cb func OnEnhancedCraftRecipeCraftedEvent(event: ref<EnhancedCraftRecipeCrafted>) -> Bool {
  let name: String;
  let itemId: ItemID;
  let system: ref<EnhancedCraftSystem>;
  let inputText: String = this.m_nameInput.GetText();
  let shouldPersist: Bool = event.isClothes || event.isWeapon;
  // Persist custom name if weapon or clothes was crafted and input is not empty
  if shouldPersist && NotEquals(inputText, "") {
    system = EnhancedCraftSystem.GetInstance(this.m_player.GetGame());
    itemId = event.itemId;
    name = this.m_nameInput.GetText();
    system.AddCustomName(itemId, name);
    system.RefreshPlayerInventory();
  };
  this.m_nameInput.SetText("");
  this.RestoreOriginalName();
}

// -- Restore original recipe name in crafting panel
@addMethod(CraftingMainGameController)
public func RestoreOriginalName() -> Void {
	this.m_craftedItemName.SetText(this.m_originalName);
}
