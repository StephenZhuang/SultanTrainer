// ViewModels/AppViewModel.swift
import Foundation
import Combine
import SwiftUI

/// 全局视图模型，持有存档数据和修改状态
class AppViewModel: ObservableObject {
    // MARK: - 服务
    let configLoader = ConfigLoader()
    let saveManager = SaveManager()
    var cardService: CardService!
    let quickModifiers = QuickModifiers()
    
    // MARK: - 存档数据
    @Published var saveData: SaveData?
    @Published var globalData: GlobalData?
    
    // MARK: - 状态
    @Published var isLoading = true
    @Published var hasUnsavedChanges = false
    @Published var lastSaveMessage: String?
    @Published var errorMessage: String?
    @Published var showSavePicker = false
    @Published var availableSaves: [SaveManager.SaveInfo] = []
    
    // MARK: - 导航
    @Published var selectedSidebarItem: SidebarItem? = .quickModify
    
    init() {
        cardService = CardService(configLoader: configLoader)
    }
    
    /// 启动时自动加载
    func initialize() {
        isLoading = true
        
        // 加载游戏配置
        configLoader.locateConfigDirectory()
        try? configLoader.loadAllConfigs()
        
        // 扫描存档
        let saves = saveManager.scanSaveDirectories()
        availableSaves = saves
        
        if saves.isEmpty {
            isLoading = false
            errorMessage = "未检测到存档，请先运行游戏"
            return
        }
        
        if saves.count == 1 {
            loadSave(at: saves[0])
        } else {
            // 多个存档，让用户选择
            isLoading = false
            showSavePicker = true
        }
    }
    
    /// 加载指定存档
    func loadSave(at saveInfo: SaveManager.SaveInfo) {
        isLoading = true
        errorMessage = nil
        
        do {
            saveData = try saveManager.loadSave(from: saveInfo.autoSavePath)
            saveManager.currentSavePath = saveInfo.autoSavePath
            
            if FileManager.default.fileExists(atPath: saveInfo.globalPath.path) {
                globalData = try saveManager.loadGlobal(from: saveInfo.globalPath)
                saveManager.currentGlobalPath = saveInfo.globalPath
            }
            
            hasUnsavedChanges = false
        } catch {
            errorMessage = "存档加载失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// 保存存档
    func save() {
        guard let save = saveData, let path = saveManager.currentSavePath else { return }
        
        do {
            try saveManager.saveSave(save, to: path)
            hasUnsavedChanges = false
            lastSaveMessage = "已保存"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if self.lastSaveMessage == "已保存" {
                    self.lastSaveMessage = nil
                }
            }
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }
    
    /// 保存全局数据
    func saveGlobal() {
        guard let global = globalData, let path = saveManager.currentGlobalPath else { return }
        
        do {
            try saveManager.saveGlobal(global, to: path)
            lastSaveMessage = "已保存"
        } catch {
            errorMessage = "保存失败: \(error.localizedDescription)"
        }
    }
    
    /// 刷新存档（重新从磁盘读取）
    func reloadSave() {
        guard let savePath = saveManager.currentSavePath else { return }

        isLoading = true
        errorMessage = nil

        do {
            saveData = try saveManager.loadSave(from: savePath)

            if let globalPath = saveManager.currentGlobalPath,
               FileManager.default.fileExists(atPath: globalPath.path) {
                globalData = try saveManager.loadGlobal(from: globalPath)
            }

            hasUnsavedChanges = false
            lastSaveMessage = "已刷新"

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if self.lastSaveMessage == "已刷新" {
                    self.lastSaveMessage = nil
                }
            }
        } catch {
            errorMessage = "刷新失败: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// 标记数据已修改
    func markModified() {
        hasUnsavedChanges = true
    }
}
