import FeatureCore
import SwiftUI

@ViewAction(for: DeviceListFeature.self)
public struct DeviceListView: View {
  public let store: StoreOf<DeviceListFeature>
  
  public init(store: StoreOf<DeviceListFeature>) {
    self.store = store
  }
  
  public var body: some View {
    ScrollView {
      VStack(spacing: DesignTokens.Spacing.x8) {
        filterView

        if store.selectedFilter.showsIOS {
          BootedDeviceView(devices: store.filteredIOSBootedDevices) {
            send(.iOSDeviceTapped($0))
          }

          ForEach(store.filteredIOSShutdownGroups) { group in
            DeviceGroupView(group: group) {
              send(.iOSDeviceTapped($0))
            }
          }
        }

        if store.selectedFilter.showsAndroid {
          androidDevicesView
        }
      }
      .padding(.horizontal, DesignTokens.Spacing.x6)
      .padding(.vertical, DesignTokens.Spacing.x8)
    }
    .onAppear {
      send(.onAppear)
    }
    .background(DesignTokens.Colors.background)
  }

  private var filterView: some View {
    HStack(spacing: DesignTokens.Spacing.x2) {
      ForEach(DeviceListFeature.DeviceFilter.allCases) { filter in
        Button {
          send(.filterTapped(filter))
        } label: {
          Text(filter.title)
            .font(DesignTokens.Typography.button.font)
            .foregroundStyle(
              store.selectedFilter == filter
                ? DesignTokens.Colors.surface
                : DesignTokens.Colors.text
            )
            .padding(.vertical, DesignTokens.Spacing.x2)
            .padding(.horizontal, DesignTokens.Spacing.x4)
            .frame(maxWidth: .infinity)
            .background {
              RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                .fill(
                  store.selectedFilter == filter
                    ? DesignTokens.Colors.accent
                    : DesignTokens.Colors.surface
                )
            }
            .overlay {
              RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
                .stroke(DesignTokens.Colors.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var androidDevicesView: some View {
    VStack(spacing: .zero) {
      HStack(spacing: DesignTokens.Spacing.x2) {
        Text("Android 기기")
          .font(DesignTokens.Typography.title2.font)
          .foregroundStyle(DesignTokens.Colors.text)

        Text("\(store.filteredAndroidBootedDevices.count + store.filteredAndroidShutdownDevices.count)")
          .font(DesignTokens.Typography.caption.font)
          .foregroundStyle(DesignTokens.Colors.accent)
          .padding(.vertical, DesignTokens.Spacing.x1)
          .padding(.horizontal, DesignTokens.Spacing.x2)
          .background {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
              .fill(DesignTokens.Colors.surfaceAccent)
          }

        Spacer()
      }
      .padding(.bottom, DesignTokens.Spacing.x3)

      if store.filteredAndroidBootedDevices.isEmpty && store.filteredAndroidShutdownDevices.isEmpty {
        Text("표시할 Android 에뮬레이터가 없습니다.")
          .font(DesignTokens.Typography.body.font)
          .foregroundStyle(DesignTokens.Colors.mutedText)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(DesignTokens.Spacing.x4)
          .background {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
              .fill(DesignTokens.Colors.surface)
          }
          .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
              .stroke(DesignTokens.Colors.border, lineWidth: 1)
          }
      } else {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3)) {
          ForEach(store.filteredAndroidBootedDevices + store.filteredAndroidShutdownDevices) { device in
            androidDeviceCell(device)
          }
        }
      }
    }
  }

  private func androidDeviceCell(_ device: EmulatorDevice) -> some View {
    VStack(alignment: .leading, spacing: .zero) {
      HStack(spacing: 4) {
        DeviceStateBadge(state: device.state)
        Text("Android")
          .font(DesignTokens.Typography.caption.font)
          .foregroundStyle(DesignTokens.Colors.mutedText)
          .padding(.vertical, DesignTokens.Spacing.x1)
          .padding(.horizontal, DesignTokens.Spacing.x2)
          .background {
            RoundedRectangle(cornerRadius: DesignTokens.Radius.control)
              .foregroundStyle(DesignTokens.Colors.surfaceAccent)
          }
      }

      Text(device.name)
        .font(DesignTokens.Typography.headline.font)
        .foregroundStyle(DesignTokens.Colors.text)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, DesignTokens.Spacing.x2)

      Text(device.serial)
        .font(DesignTokens.Typography.caption.font)
        .foregroundStyle(DesignTokens.Colors.mutedText)
        .lineLimit(1)
        .truncationMode(.middle)
        .padding(.top, DesignTokens.Spacing.x2)

      Button {
        send(.androidDeviceTapped(device))
      } label: {
        Text(device.state.isBooted ? "종료하기" : "실행하기")
          .font(DesignTokens.Typography.button.font)
      }
      .buttonStyle(.borderedProminent)
      .tint(DesignTokens.Colors.accent)
      .padding(.top, DesignTokens.Spacing.x4)
    }
    .cardContainer()
  }
}
